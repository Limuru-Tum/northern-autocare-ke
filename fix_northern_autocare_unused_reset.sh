#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
SOURCE_FILE="src/components/booking/AppointmentForm.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/northern-autocare-ke-reset-fix-backup-$STAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" ]] || fail "package.json not found in $PROJECT_DIR"
[[ -f "$PROJECT_DIR/$SOURCE_FILE" ]] || fail "$SOURCE_FILE not found. No changes made."
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."

mkdir -p "$BACKUP_DIR/$(dirname "$SOURCE_FILE")"
cp -p "$PROJECT_DIR/$SOURCE_FILE" "$BACKUP_DIR/$SOURCE_FILE"
log backup "Saved original AppointmentForm.tsx to $BACKUP_DIR/$SOURCE_FILE"

python3 - "$PROJECT_DIR/$SOURCE_FILE" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
old = "    reset,\n    setValue,"
new = "    setValue,"
count = s.count(old)
if count == 0:
    if "    reset," not in s:
        print("[ok] The unused reset binding is already absent; no source change needed.")
        raise SystemExit(0)
    raise SystemExit("[error] Found reset, but not in the expected form-state destructuring. No source change made.")
if count != 1:
    raise SystemExit(f"[error] Expected one reset binding before setValue, found {count}. No source change made.")
p.write_text(s.replace(old, new, 1))
print("[fix] Removed the unused reset binding from AppointmentForm.tsx")
PY

cd "$PROJECT_DIR"
run_check() {
  local label="$1"; shift
  log check "$label"
  "$@"
  log ok "$label passed"
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "ESLint" npm run lint
run_check "Production build" npm run build
log done "Unused reset binding fixed and all verification commands completed. Backup: $BACKUP_DIR"
