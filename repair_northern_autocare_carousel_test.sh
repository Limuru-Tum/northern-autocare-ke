#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/northern-autocare-ke-fix-backup-$STAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/src/components/home/HeroCarousel.tsx" ]] || fail "Missing src/components/home/HeroCarousel.tsx"
[[ -f "$PROJECT_DIR/vite.config.ts" ]] || fail "Missing vite.config.ts"
[[ -f "$PROJECT_DIR/src/App.test.tsx" ]] || fail "Missing src/App.test.tsx"
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."

mkdir -p "$BACKUP_DIR"
for file in src/components/home/HeroCarousel.tsx vite.config.ts src/App.test.tsx; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
log backup "Backed up carousel, Vite, and test files to $BACKUP_DIR"

cd "$PROJECT_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])

# Keep the carousel's visual line break while exposing the complete phrase to
# assistive technology and stable role/name queries in React Testing Library.
carousel_path = root / "src/components/home/HeroCarousel.tsx"
carousel = carousel_path.read_text()

old_heading = '<h1>{activeSlide.title[0]}<br /><span>{activeSlide.title[1]}</span></h1>'
new_heading = '<h1 aria-label={activeSlide.title.join(" ")}>{activeSlide.title[0]}<br /><span>{activeSlide.title[1]}</span></h1>'

if 'aria-label={activeSlide.title.join(" ")}' in carousel:
    print("[ok] Hero heading already has a complete accessible name")
elif old_heading in carousel:
    carousel = carousel.replace(old_heading, new_heading, 1)
    carousel_path.write_text(carousel)
    print("[fix] Added a complete accessible name to the multi-line hero heading")
else:
    pattern = re.compile(
        r'<h1>\s*\{activeSlide\.title\[0\]\}\s*<br\s*/>\s*'
        r'<span>\s*\{activeSlide\.title\[1\]\}\s*</span>\s*</h1>'
    )
    updated, count = pattern.subn(new_heading, carousel, count=1)
    if count:
        carousel_path.write_text(updated)
        print("[fix] Added a complete accessible name to the multi-line hero heading")
    else:
        raise SystemExit(
            "[error] Could not safely identify the hero heading markup. "
            "No Vite or test configuration changes were made."
        )

# A previous script stored backup copies below the project directory. Vitest
# discovered a backup App.test.tsx and ran it as a second test file. Limit
# discovery to the project's real src tests and exclude backups defensively.
vite_path = root / "vite.config.ts"
vite = vite_path.read_text()

include_line = '    include: ["src/**/*.test.ts", "src/**/*.test.tsx", "src/**/*.spec.ts", "src/**/*.spec.tsx"],'
exclude_line = '    exclude: ["**/node_modules/**", "**/dist/**", "**/coverage/**", "**/.git/**", "**/.repair-backups/**", "**/*-backup-*/**"],'

test_open = re.search(r'(?m)^(\s*)test\s*:\s*\{', vite)
if not test_open:
    raise SystemExit("[error] Could not find the Vitest `test: {` block in vite.config.ts")

insertions = []
if 'include: ["src/**/*.test.ts"' not in vite:
    insertions.append(include_line)
else:
    print("[ok] Vitest source-test include patterns already configured")
if '"**/.repair-backups/**"' not in vite:
    insertions.append(exclude_line)
else:
    print("[ok] Vitest backup exclusion already configured")

if insertions:
    insert_at = test_open.end()
    prefix = "\n" + "\n".join(insertions) + "\n"
    vite = vite[:insert_at] + prefix + vite[insert_at:]
vite_path.write_text(vite)
print("[fix] Limited Vitest discovery to real source tests and excluded backup folders")
PY

run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then
    log ok "$label passed"
  else
    fail "$label failed. Original files are backed up at: $BACKUP_DIR"
  fi
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "ESLint" npm run lint
run_check "Production build" npm run build

log done "Carousel accessibility/test-discovery repair completed successfully."
log done "Backup: $BACKUP_DIR"
