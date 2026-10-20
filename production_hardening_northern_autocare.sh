#!/usr/bin/env bash
set -Eeuo pipefail

# Northern Autocare KE — frontend production-hardening pass.
# Safe to re-run: backs up relevant files outside the project and applies
# guarded, idempotent edits only to the known React/Vite project structure.

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/northern-autocare-production-backup-$STAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project folder not found: $PROJECT_DIR"
for file in package.json index.html vite.config.ts src/App.tsx src/App.test.tsx src/index.css src/config/business.ts src/data/services.ts src/components/booking/AppointmentForm.tsx src/components/ui/button.tsx; do
  [[ -f "$PROJECT_DIR/$file" ]] || fail "Required project file missing: $PROJECT_DIR/$file. No changes made."
done
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."
command -v node >/dev/null 2>&1 || fail "Node.js is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."
[[ -x "$PROJECT_DIR/node_modules/.bin/vite" ]] || fail "Dependencies are not installed in the project. Run npm install inside $PROJECT_DIR first."

# Keep the backup outside the project so Vitest and Oxlint cannot discover old source copies.
mkdir -p "$BACKUP_DIR"
for file in package.json index.html vite.config.ts src/App.tsx src/App.test.tsx src/index.css src/components/booking/AppointmentForm.tsx src/components/ui/button.tsx; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
for file in src/components/booking/DeferredAppointmentForm.tsx public/favicon.svg public/robots.txt PRODUCTION_READINESS.md; do
  if [[ -f "$PROJECT_DIR/$file" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
  fi
done
log backup "Saved current source/configuration outside the project: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import json
import re
import sys

root = Path(sys.argv[1])

required = [
    "package.json", "index.html", "vite.config.ts", "src/App.tsx", "src/App.test.tsx",
    "src/index.css", "src/components/booking/AppointmentForm.tsx", "src/components/ui/button.tsx",
    "src/config/business.ts", "src/data/services.ts"
]
for relative in required:
    if not (root / relative).is_file():
        raise SystemExit(f"[error] Missing expected file: {relative}. No source/config files rewritten.")

# Read and transform in memory first; write only after structural preflight succeeds.
files = {relative: (root / relative).read_text() for relative in required if relative != "package.json"}
try:
    pkg = json.loads((root / "package.json").read_text())
except json.JSONDecodeError as exc:
    raise SystemExit(f"[error] package.json is not valid JSON: {exc}")

changes = []

# ---------- App hardening: bounded crimson pointer effect, year constant, deferred form ----------
app = files["src/App.tsx"]
old_booking_import = 'import { AppointmentForm } from "@/components/booking/AppointmentForm";'
new_booking_import = 'import { DeferredAppointmentForm } from "@/components/booking/DeferredAppointmentForm";'
if old_booking_import in app:
    app = app.replace(old_booking_import, new_booking_import, 1)
    if app.count("<AppointmentForm />") != 1:
        raise SystemExit("[error] Expected exactly one <AppointmentForm /> in src/App.tsx. No source files rewritten.")
    app = app.replace("<AppointmentForm />", "<DeferredAppointmentForm />", 1)
    changes.append("Defer the appointment-form code until the booking section approaches the viewport")
elif new_booking_import in app and "<DeferredAppointmentForm />" in app:
    changes.append("Appointment form already uses the deferred loader")
else:
    raise SystemExit("[error] App.tsx booking component structure was not recognized. No source files rewritten.")

# Avoid calculating a changing value in React render.
if "const CURRENT_YEAR = new Date().getFullYear();" not in app and "new Date().getFullYear()" in app:
    app = app.replace("new Date().getFullYear()", "CURRENT_YEAR")
    marker = "const vehicles = ["
    if marker not in app:
        raise SystemExit("[error] Cannot safely place CURRENT_YEAR constant in App.tsx. No source files rewritten.")
    app = app.replace(marker, "const CURRENT_YEAR = new Date().getFullYear();\n\n" + marker, 1)
    changes.append("Move the footer year calculation outside React render")

# Remove an unused Button import only when this module does not render <Button />.
button_import = 'import { Button } from "@/components/ui/button";'
if button_import in app and not re.search(r"<Button(?:\s|>)", app):
    app = app.replace(button_import + "\n", "", 1)
    changes.append("Remove unused Button import")

# Keep pointer-driven colours in the crimson/cherry-red brand family.
old_hue_line = "const hue = Math.round(28 + x * 145);"
if old_hue_line in app:
    app = app.replace(old_hue_line, "const hue = Math.round(345 + x * 15);\n    const saturation = Math.round(74 + x * 10);\n    const lightness = Math.round(47 + x * 8);", 1)
    old_accent = '`hsl(${hue} 76% 54%)`'
    if old_accent not in app:
        raise SystemExit("[error] Found the old cursor hue but not the expected HSL accent expression. No source files rewritten.")
    app = app.replace(old_accent, '`hsl(${hue} ${saturation}% ${lightness}%)`', 1)
    changes.append("Keep cursor-reactive ambience in crimson and cherry-red hues")
files["src/App.tsx"] = app

# ---------- Booking form: remove the previously reported unused reset binding if unused ----------
form = files["src/components/booking/AppointmentForm.tsx"]
reset_binding = "    reset,\n    setValue,"
if reset_binding in form and not re.search(r"\breset\s*\(", form):
    form = form.replace(reset_binding, "    setValue,", 1)
    changes.append("Remove unused react-hook-form reset binding")
files["src/components/booking/AppointmentForm.tsx"] = form

# ---------- Vitest: keep old backups out of test discovery ----------
vite = files["vite.config.ts"]
test_match = re.search(r"\btest\s*:\s*\{", vite)
if not test_match:
    raise SystemExit("[error] Could not find the Vitest test configuration in vite.config.ts. No source files rewritten.")
line_start = vite.rfind("\n", 0, test_match.start()) + 1
line_indent = re.match(r"[ \t]*", vite[line_start:test_match.start()]).group(0)
indent = line_indent + "  "
if not re.search(r"(?m)^\s*include\s*:", vite[test_match.end():]):
    insertion = f'\n{indent}include: ["src/**/*.test.ts", "src/**/*.test.tsx", "src/**/*.spec.ts", "src/**/*.spec.tsx"],'
    vite = vite[:test_match.end()] + insertion + vite[test_match.end():]
    changes.append("Scope Vitest tests to real source test files")
if not re.search(r"(?m)^\s*exclude\s*:", vite[test_match.end():]):
    insertion = f'\n{indent}exclude: ["**/node_modules/**", "**/dist/**", "**/coverage/**", "**/.git/**", "**/.repair-backups/**", "**/*-backup-*/**"],'
    # Re-find after include insertion to avoid stale positions.
    test_match = re.search(r"\btest\s*:\s*\{", vite)
    if not test_match:
        raise SystemExit("[error] Could not re-locate Vitest test block while adding excludes. No source files rewritten.")
    vite = vite[:test_match.end()] + insertion + vite[test_match.end():]
    changes.append("Exclude backup and generated folders from Vitest")
files["vite.config.ts"] = vite

# ---------- App test: wait for deferred form UI to render asynchronously ----------
test = files["src/App.test.tsx"]
if 'it("shows the service catalogue and appointment form", () => {' in test:
    test = test.replace('it("shows the service catalogue and appointment form", () => {', 'it("shows the service catalogue and appointment form", async () => {', 1)
    changes.append("Make booking-form test await the deferred component")
if 'screen.getByRole("heading", { name: /Tell us what your vehicle needs/i })' in test:
    test = test.replace('screen.getByRole("heading", { name: /Tell us what your vehicle needs/i })', 'await screen.findByRole("heading", { name: /Tell us what your vehicle needs/i })', 1)
if 'screen.getByLabelText(/Phone number/i)' in test and 'it("shows the service catalogue and appointment form", async () =>' in test:
    test = test.replace('screen.getByLabelText(/Phone number/i)', 'await screen.findByLabelText(/Phone number/i)', 1)
files["src/App.test.tsx"] = test

# ---------- Avoid lint scanning old project backups ----------
pkg.setdefault("scripts", {})
lint_script = pkg["scripts"].get("lint")
if not isinstance(lint_script, str):
    raise SystemExit("[error] package.json has no usable lint script. No source/config files rewritten.")
if re.fullmatch(r"\s*oxlint\s+\.\s*", lint_script):
    pkg["scripts"]["lint"] = "oxlint src"
    changes.append("Limit Oxlint to application source instead of archived backups")
elif re.fullmatch(r"\s*eslint\s+\.\s*", lint_script):
    pkg["scripts"]["lint"] = "eslint src"
    changes.append("Limit ESLint to application source instead of archived backups")
elif not re.search(r"\b(?:oxlint|eslint)\s+src\b", lint_script):
    raise SystemExit(f"[error] Unexpected lint script ({lint_script!r}); refusing to rewrite it blindly.")

check_command = "npm run typecheck && npm run test && npm run lint && npm run build"
if pkg["scripts"].get("check") != check_command:
    pkg["scripts"]["check"] = check_command
    changes.append("Add one repeatable npm run check quality gate")

# ---------- Production metadata: no invented domain/canonical URL ----------
html = files["index.html"]
if "</head>" not in html.lower():
    raise SystemExit("[error] index.html has no </head> tag. No source/config files rewritten.")
html = re.sub(r"<title\b[^>]*>.*?</title>", "<title>Northern Autocare KE | Vehicle Service &amp; Repairs in Lodwar</title>", html, count=1, flags=re.I | re.S)
if not re.search(r"<title\b", html, re.I):
    html = re.sub(r"</head>", "    <title>Northern Autocare KE | Vehicle Service &amp; Repairs in Lodwar</title>\n  </head>", html, count=1, flags=re.I)

def upsert_meta(source: str, attribute: str, key: str, content: str) -> str:
    # Match metadata by its name/property regardless of attribute ordering.
    pattern = re.compile(r"<meta\b(?=[^>]*\b" + re.escape(attribute) + r"=[\"']" + re.escape(key) + r"[\"'])[^>]*>", re.I)
    tag = f'<meta {attribute}="{key}" content="{content}" />'
    if pattern.search(source):
        return pattern.sub(tag, source, count=1)
    insert_point = re.search(r"</head>", source, re.I)
    if not insert_point:
        raise SystemExit("[error] Cannot insert metadata without </head>.")
    return source[:insert_point.start()] + "    " + tag + "\n  " + source[insert_point.start():]

metadata = [
    ("name", "description", "Northern Autocare KE in Lodwar, Turkana County, offers wheel balancing and alignment, computerized diagnostics, vehicle servicing, engine overhauls, mechanical repairs, and automotive spare parts."),
    ("name", "theme-color", "#C8102E"),
    ("name", "robots", "index, follow"),
    ("name", "referrer", "strict-origin-when-cross-origin"),
    ("property", "og:type", "website"),
    ("property", "og:title", "Northern Autocare KE | Vehicle Service & Repairs in Lodwar"),
    ("property", "og:description", "Vehicle servicing, computerized diagnostics, wheel alignment, engine work, and spare-parts support in Lodwar, Turkana County."),
]
for attr, key, content in metadata:
    html = upsert_meta(html, attr, key, content)
if not re.search(r'<link\b(?=[^>]*\brel=["\']icon["\'])', html, re.I):
    html = re.sub(r"</head>", '    <link rel="icon" type="image/svg+xml" href="./favicon.svg" />\n  </head>', html, count=1, flags=re.I)
files["index.html"] = html
changes.append("Refresh SEO/social metadata and crimson browser theme color")

# ---------- CSS: defer loader state, keep it visually aligned with the booking card ----------
css = files["src/index.css"]
css_marker = "/* Production deferred booking-form states — Northern Autocare KE */"
if css_marker not in css:
    css += '''\n\n/* Production deferred booking-form states — Northern Autocare KE */
.booking-form-boundary { width: 100%; min-width: 0; }
.booking-loading {
  display: flex; min-height: 440px; width: 100%; flex-direction: column;
  align-items: center; justify-content: center; gap: 12px; padding: 28px;
  border: 1px solid rgb(200 16 46 / 12%); border-radius: 20px;
  background: linear-gradient(145deg, #fff 0%, #fffafb 100%);
  color: #6f626b; text-align: center;
}
.booking-loading-mark {
  display: grid; width: 48px; height: 48px; place-items: center;
  border: 1px solid rgb(200 16 46 / 17%); border-radius: 15px;
  background: #fff0f2; color: #c8102e;
}
.booking-loading strong { color: #30252d; font-size: 13px; font-weight: 800; }
.booking-loading span:last-child { max-width: 290px; font-size: 11px; line-height: 1.7; }
.booking-loading-dot { width: 6px; height: 6px; border-radius: 50%; background: #c8102e; box-shadow: 0 0 0 5px rgb(200 16 46 / 9%); }
@media (max-width: 720px) {
  .booking-loading { min-height: 320px; padding: 22px 16px; border-radius: 17px; }
}
@media (prefers-reduced-motion: reduce) {
  .booking-loading-dot { box-shadow: none; }
}
'''
    changes.append("Style the booking-form loading state for desktop and mobile")
files["src/index.css"] = css

# ---------- Remove the shadcn helper export only when no source file imports it ----------
button_path = root / "src/components/ui/button.tsx"
button_source = button_path.read_text()
external_uses = []
for source_path in (root / "src").rglob("*"):
    if not source_path.is_file() or source_path.suffix not in {".ts", ".tsx", ".js", ".jsx"} or source_path.resolve() == button_path.resolve():
        continue
    try:
        if "buttonVariants" in source_path.read_text():
            external_uses.append(str(source_path.relative_to(root)))
    except UnicodeDecodeError:
        continue
if not external_uses and "export { Button, buttonVariants };" in button_source:
    files["src/components/ui/button.tsx"] = button_source.replace("export { Button, buttonVariants };", "export { Button };", 1)
    changes.append("Remove unused buttonVariants public export (preserved if referenced)")
else:
    files["src/components/ui/button.tsx"] = button_source

# ---------- Public assets / go-live checklist (create only when absent) ----------
public_dir = root / "public"
public_dir.mkdir(parents=True, exist_ok=True)
favicon_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="Northern Autocare KE">
  <rect width="64" height="64" rx="16" fill="#C8102E"/>
  <path d="M40.8 11.5a17 17 0 0 0-20.4 21.1L9.8 43.2a5.5 5.5 0 0 0 7.8 7.8l10.6-10.6a17 17 0 0 0 21.1-20.4l-9.7 9.7-8.5-8.5 9.7-9.7Z" fill="none" stroke="#fff" stroke-linecap="round" stroke-linejoin="round" stroke-width="4.5"/>
</svg>
'''
if not (public_dir / "favicon.svg").exists():
    (public_dir / "favicon.svg").write_text(favicon_svg)
    changes.append("Add a lightweight crimson SVG favicon")
if not (public_dir / "robots.txt").exists():
    (public_dir / "robots.txt").write_text("User-agent: *\nAllow: /\n\n# Add a Sitemap: URL after the production domain is confirmed.\n")
    changes.append("Add a basic robots.txt without inventing a sitemap/domain")

checklist_path = root / "PRODUCTION_READINESS.md"
if not checklist_path.exists():
    checklist_path.write_text('''# Northern Autocare KE — Production Readiness Checklist

## Confirm business information before launch
- [ ] Confirm the workshop phone and WhatsApp numbers with management.
- [ ] Confirm the public address/pin and actual opening hours.
- [ ] Confirm the listed service catalogue, vehicle categories, parts availability wording, and any prices.
- [ ] Get management approval for the mission, vision, descriptions, and all claims on the site.
- [ ] Replace illustrative/stock workshop images with owned or properly licensed photographs when available.
- [ ] Confirm that the official business name and spelling are consistent everywhere.

## Appointment requests and privacy
- [ ] Send a test request to the business WhatsApp account from an actual phone.
- [ ] Verify that names, phone number, vehicle details, service, date, time, and notes are encoded correctly.
- [ ] Confirm the form states that a submitted WhatsApp message is only a request, not a confirmed appointment.
- [ ] Add a management-approved privacy notice explaining that users choose to send their details through WhatsApp.
- [ ] Do not advertise live availability, automatic confirmation, secure database storage, or an admin dashboard: the current frontend does not provide those backend capabilities.

## Technical release checks
- [ ] Run `npm run check` and resolve all errors.
- [ ] Run `npm run build` and `npm run preview`; test the preview on desktop and a real mobile device.
- [ ] Test keyboard-only navigation, visible focus, form errors, reduced-motion preferences, and color contrast.
- [ ] Check that every hero/service image loads and has appropriate alternative text.
- [ ] Confirm the production domain before adding canonical URLs and a sitemap.
- [ ] Configure HTTPS and appropriate security/cache headers on the hosting platform.
- [ ] Test external links, telephone links, WhatsApp message destination, and mobile navigation after deployment.
- [ ] Check performance in Lighthouse or PageSpeed Insights after deployment; avoid claiming a score until measured.

## Current scope
This is a static React frontend. Appointment details are prepared client-side and passed to WhatsApp only when the visitor chooses to open/send the message. There is no database, live availability checker, user account, or booking-management backend in this version.
''')
    changes.append("Add a production go-live checklist with real frontend limitations documented")

# Persist transformed existing files only after all expected structure is validated.
for relative, content in files.items():
    (root / relative).write_text(content)
(root / "package.json").write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")

# Save the async component only after all checks above have succeeded.
deferred_path = root / "src/components/booking/DeferredAppointmentForm.tsx"
if not deferred_path.exists():
    deferred_path.parent.mkdir(parents=True, exist_ok=True)
    deferred_path.write_text('''import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { Wrench } from "lucide-react";

const AppointmentForm = lazy(() =>
  import("./AppointmentForm").then((module) => ({ default: module.AppointmentForm })),
);

function BookingFormPlaceholder({ message, loading = false }: { message: string; loading?: boolean }) {
  return (
    <div className="booking-card booking-loading" role={loading ? "status" : undefined} aria-live={loading ? "polite" : undefined}>
      <span className="booking-loading-mark"><Wrench size={22} aria-hidden="true" /></span>
      <span className="booking-loading-dot" aria-hidden="true" />
      <strong>{message}</strong>
      <span>{loading ? "Preparing the appointment form." : "The form loads automatically as you approach this section."}</span>
    </div>
  );
}

/** Load form code only when the booking section is near the visible viewport. */
export function DeferredAppointmentForm() {
  const boundaryRef = useRef<HTMLDivElement>(null);
  const [shouldLoad, setShouldLoad] = useState(
    () => typeof window === "undefined" || typeof IntersectionObserver === "undefined",
  );

  useEffect(() => {
    if (shouldLoad) return;
    const boundary = boundaryRef.current;
    if (!boundary || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          setShouldLoad(true);
          observer.disconnect();
        }
      },
      { rootMargin: "420px 0px" },
    );
    observer.observe(boundary);
    return () => observer.disconnect();
  }, [shouldLoad]);

  return (
    <div className="booking-form-boundary" ref={boundaryRef}>
      {shouldLoad ? (
        <Suspense fallback={<BookingFormPlaceholder message="Preparing your appointment form…" loading />}>
          <AppointmentForm />
        </Suspense>
      ) : (
        <BookingFormPlaceholder message="Appointment booking, made simple." />
      )}
    </div>
  );
}
''')
    changes.append("Add an IntersectionObserver-based lazy booking-form wrapper")

# Print idempotent changes and files created.
for item in changes:
    print(f"[fix] {item}")
if not changes:
    print("[ok] No source transformations were needed; production configuration was already in place.")
print("[ok] Updated project files after structural preflight")
PY

cd "$PROJECT_DIR"

# Verify there is a check command and print versions without making network requests.
log info "Using Node $(node --version), npm $(npm --version)"

run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then
    log ok "$label passed"
  else
    fail "$label failed. Current files are backed up at: $BACKUP_DIR. Review the error before rerunning."
  fi
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "Lint" npm run lint
run_check "Production build" npm run build

# Inspect generated assets. This is informational and won't fail on a warning.
node --input-type=module <<'NODE'
import fs from 'node:fs';
import path from 'node:path';
const dir = 'dist/assets';
if (!fs.existsSync(dir)) {
  console.log('[warn] dist/assets was not found after the build.');
  process.exit(0);
}
const files = fs.readdirSync(dir)
  .filter((name) => name.endsWith('.js'))
  .map((name) => ({ name, bytes: fs.statSync(path.join(dir, name)).size }))
  .sort((a, b) => b.bytes - a.bytes);
console.log('[report] Production JavaScript bundle sizes:');
for (const file of files) {
  const kb = (file.bytes / 1024).toFixed(1);
  console.log(`  ${kb.padStart(7)} KB  ${file.name}`);
}
const largest = files[0];
if (largest && largest.bytes > 500 * 1024) {
  console.log('[note] Largest JavaScript chunk remains above 500 KB. Consider a real-device performance check and further code splitting.');
} else {
  console.log('[ok] Largest JavaScript chunk is below 500 KB.');
}
NODE

log done "Production-hardening pass finished. Backup: $BACKUP_DIR"
log next "Review $PROJECT_DIR/PRODUCTION_READINESS.md before publishing. This frontend sends requests through WhatsApp; it does not yet store/confirm appointments in a backend."
