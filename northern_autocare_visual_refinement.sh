#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/Desktop/northern-autocare-ke-visual-backup-$STAMP"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
for file in \
  package.json src/App.tsx src/index.css src/components/layout/SiteHeader.tsx \
  src/components/home/HeroCarousel.tsx src/components/ui/button.tsx; do
  [[ -f "$PROJECT_DIR/$file" ]] || fail "Expected file missing: $PROJECT_DIR/$file. No files changed."
done
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."

mkdir -p "$BACKUP_DIR"
for file in package.json src/App.tsx src/index.css src/components/layout/SiteHeader.tsx src/components/home/HeroCarousel.tsx src/components/ui/button.tsx; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
log backup "Saved affected files outside the project: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import json, re, sys

root = Path(sys.argv[1])

# 1) Ensure lint only scans real application source, never backups or generated dist files.
pkg_path = root / "package.json"
pkg = json.loads(pkg_path.read_text())
old_lint = pkg.get("scripts", {}).get("lint", "")
if not old_lint:
    raise SystemExit("[error] package.json has no lint script; refusing to invent one.")
new_lint = re.sub(r"\boxlint\s+\.\s*$", "oxlint src", old_lint)
new_lint = re.sub(r"\boxlint\s+src\s*$", "oxlint src", new_lint)
if "oxlint src" not in new_lint:
    raise SystemExit(f"[error] Unexpected lint command: {old_lint!r}; no package script change saved.")
pkg["scripts"]["lint"] = new_lint
pkg_path.write_text(json.dumps(pkg, indent=2) + "\n")
print("[fix] Restricted ESLint/Oxlint to src/ so local backups are not linted")

# 2) Remove a genuinely unused Button import from App.tsx if the component isn't used there.
app_path = root / "src/App.tsx"
app = app_path.read_text()
if 'import { Button } from "@/components/ui/button";' in app and not re.search(r"<Button(?:\s|>)", app):
    app = app.replace('import { Button } from "@/components/ui/button";\n', "")
    print("[fix] Removed unused Button import from App.tsx")
else:
    print("[skip] App.tsx Button import is absent or used")

# 3) Move the footer year lookup outside the React render function to keep render pure.
if "new Date().getFullYear()" in app:
    if "const CURRENT_YEAR = new Date().getFullYear();" not in app:
        app = app.replace("new Date().getFullYear()", "CURRENT_YEAR")
        component_match = re.search(r"(?m)^export default function App\s*\(", app)
        if not component_match:
            raise SystemExit("[error] Could not locate 'export default function App'; year patch not saved.")
        app = app[:component_match.start()] + "const CURRENT_YEAR = new Date().getFullYear();\n\n" + app[component_match.start():]
        print("[fix] Moved footer year lookup to a module-level constant")
    else:
        app = app.replace("{new Date().getFullYear()}", "{CURRENT_YEAR}")
        print("[fix] Reused existing CURRENT_YEAR constant in footer")
else:
    print("[skip] Footer already uses a stable year value")
app_path.write_text(app)

# 4) Remove useEffect only if it is imported but never used in the header component.
header_path = root / "src/components/layout/SiteHeader.tsx"
header = header_path.read_text()
if "useEffect" in header and re.search(r"import\s*\{[^}]*\buseEffect\b[^}]*\}\s*from\s*\"react\"", header):
    code_without_imports = re.sub(r"(?m)^import .*?;\s*$", "", header)
    if not re.search(r"\buseEffect\s*\(", code_without_imports):
        header = re.sub(r"import\s*\{\s*useEffect\s*,\s*useState\s*\}\s*from\s*\"react\";", 'import { useState } from "react";', header, count=1)
        header = re.sub(r"import\s*\{\s*useState\s*,\s*useEffect\s*\}\s*from\s*\"react\";", 'import { useState } from "react";', header, count=1)
        header_path.write_text(header)
        print("[fix] Removed unused useEffect import from SiteHeader.tsx")
    else:
        print("[skip] SiteHeader.tsx uses useEffect")
else:
    print("[skip] SiteHeader.tsx has no unused useEffect import")

# 5) Export only Button from the shadcn component when the helper isn't consumed elsewhere.
button_path = root / "src/components/ui/button.tsx"
button = button_path.read_text()
external_use = False
for path in (root / "src").rglob("*"):
    if not path.is_file() or path.suffix not in {".ts", ".tsx", ".js", ".jsx"} or path.resolve() == button_path.resolve():
        continue
    text = path.read_text(errors="ignore")
    if re.search(r"\bbuttonVariants\b", text):
        external_use = True
        break
if not external_use and "export { Button, buttonVariants };" in button:
    button = button.replace("export { Button, buttonVariants };", "export { Button };")
    button_path.write_text(button)
    print("[fix] Removed unused buttonVariants export")
else:
    print("[skip] buttonVariants is used elsewhere or export already differs")

# 6) Add a small, non-destructive visual refinement layer. Keep all existing component structure intact.
css_path = root / "src/index.css"
css = css_path.read_text()
marker = "/* Northern Autocare KE — crimson visual refinement layer */"
if marker not in css:
    polish = r'''

/* Northern Autocare KE — crimson visual refinement layer */
:root {
  --na-crimson: #c8102e;
  --na-crimson-deep: #9f1239;
  --na-crimson-bright: #e11d48;
  --na-crimson-soft: #ff7186;
}

::selection { color: #fff; background: rgb(200 16 46 / 82%); }
:focus-visible { outline-color: #e11d48; outline-offset: 4px; }

/* Consistent, confident interactions for mouse, touch, and keyboard users. */
.button,
.carousel-arrow,
.carousel-pause,
.menu-toggle,
.progress-segment,
.service-card,
.vehicle-card,
.footer-links a,
.hero-text-link {
  transition-duration: .22s;
  transition-timing-function: cubic-bezier(.2, .75, .25, 1);
}

.button-amber {
  color: #fff;
  background: linear-gradient(135deg, #e11d48 0%, #c8102e 58%, #9f1239 100%);
  box-shadow: 0 9px 24px rgb(200 16 46 / 22%);
}
.button-amber:hover {
  color: #fff;
  box-shadow: 0 14px 30px rgb(200 16 46 / 30%);
  transform: translateY(-2px);
}
.button-amber:active { transform: translateY(0); }

.site-header { box-shadow: 0 7px 24px rgb(20 18 20 / 4%); }
.brand-mark { box-shadow: inset 0 0 0 1px rgb(255 255 255 / 9%), 0 6px 16px rgb(10 10 10 / 10%); }
.desktop-nav > a:not(.button):hover,
.mobile-nav > a:not(.button):hover { color: var(--na-crimson); }

/* Premium glass treatment for the hero controls without obscuring the photography. */
.carousel-arrow,
.carousel-pause {
  background: rgb(18 18 20 / 42%);
  border-color: rgb(255 255 255 / 24%);
  color: #fff;
  backdrop-filter: blur(12px);
}
.carousel-arrow:hover,
.carousel-pause:hover {
  background: var(--na-crimson);
  border-color: var(--na-crimson);
  color: #fff;
}
.progress-segment { border-radius: 99px; overflow: hidden; }
.progress-segment:focus-visible { outline-color: #fff; outline-offset: 4px; }
.carousel-count strong { color: #ff9aaa; }

/* Crisp service cards with a restrained crimson marker on hover or keyboard focus. */
.service-card { position: relative; isolation: isolate; }
.service-card::before {
  position: absolute;
  inset: 0 auto auto 0;
  width: 100%;
  height: 3px;
  content: "";
  background: linear-gradient(90deg, var(--na-crimson), rgb(200 16 46 / 0%));
  transform: scaleX(0);
  transform-origin: left;
  transition: transform .24s ease;
}
.service-card:hover::before,
.service-card:focus-within::before { transform: scaleX(1); }
.service-icon { transition: background .22s ease, color .22s ease, transform .22s ease; }
.service-card:hover .service-icon,
.service-card:focus-within .service-icon {
  background: #fde7ec;
  color: var(--na-crimson-deep);
  transform: translateY(-2px);
}
.vehicle-card:hover,
.vehicle-card:focus-within { border-color: rgb(200 16 46 / 28%); }
.vehicle-card a { color: var(--na-crimson-deep); }

/* Clearer keyboard and focus feedback in the appointment form. */
.form-field input:focus,
.form-field select:focus,
.form-field textarea:focus {
  border-color: var(--na-crimson);
  box-shadow: 0 0 0 3px rgb(200 16 46 / 11%);
  outline: none;
}
.form-field input[aria-invalid="true"],
.form-field select[aria-invalid="true"],
.form-field textarea[aria-invalid="true"] {
  border-color: #b4233c;
}
.form-field input::placeholder,
.form-field textarea::placeholder { color: #777b83; opacity: 1; }

/* Prevent hover transforms and decorative movement from overriding reduced-motion preferences. */
@media (prefers-reduced-motion: reduce) {
  .button-amber:hover,
  .service-card:hover,
  .vehicle-card:hover,
  .floating-contact:hover { transform: none; }
  .service-card::before { transition: none; }
}

@media (max-width: 720px) {
  .carousel-arrow,
  .carousel-pause { width: 34px; height: 34px; }
  .carousel-controls { align-items: center; }
  .button-amber { box-shadow: 0 7px 18px rgb(200 16 46 / 20%); }
}
'''
    css_path.write_text(css.rstrip() + polish + "\n")
    print("[design] Added a crimson visual refinement layer without replacing existing styles")
else:
    print("[skip] Crimson visual refinement layer already exists")

# 7) Keep cursor movement in crimson hues if the earlier accent update has not been applied.
old = 'const hue = Math.round(28 + x * 145);'
new = 'const hue = Math.round(345 + x * 15);'
if old in app:
    app = app.replace(old, new, 1)
    app = app.replace('`hsl(${hue} 76% 54%)`', '`hsl(${hue} 84% 53%)`', 1)
    app_path.write_text(app)
    print("[fix] Confined cursor-reactive colour to crimson and cherry-red hues")
else:
    print("[ok] Cursor colour code already updated or uses another implementation")
PY

cd "$PROJECT_DIR"
for check in typecheck test lint build; do
  log check "npm run $check"
  npm run "$check" || fail "npm run $check failed. Source backups: $BACKUP_DIR"
done

log done "Visual refinement and source lint cleanup completed successfully."
printf '\nProject: %s\nBackup:  %s\n' "$PROJECT_DIR" "$BACKUP_DIR"
printf '\nRefresh the browser if Vite is already running. Otherwise run:\n  cd "%s"\n  npm run dev\n' "$PROJECT_DIR"
