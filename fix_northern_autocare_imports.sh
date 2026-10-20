#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${HOME}/Desktop/northern-autocare-ke"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${PROJECT_DIR}/.repair-backups/import-fix-${STAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log 'error' "$1"; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/src/App.tsx" ]] || fail "Missing file: src/App.tsx"
[[ -f "$PROJECT_DIR/src/components/layout/SiteHeader.tsx" ]] || fail "Missing file: src/components/layout/SiteHeader.tsx"
[[ -f "$PROJECT_DIR/package.json" ]] || fail "Missing package.json in $PROJECT_DIR"

mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR/src/App.tsx" "$BACKUP_DIR/App.tsx"
cp "$PROJECT_DIR/src/components/layout/SiteHeader.tsx" "$BACKUP_DIR/SiteHeader.tsx"
log setup "Backed up both files to: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

app_path = root / "src/App.tsx"
app = app_path.read_text()
unused_button_import = 'import { Button } from "@/components/ui/button";\n'
if unused_button_import in app:
    app = app.replace(unused_button_import, "", 1)
    print("[fix] Removed the unused Button import from src/App.tsx")
else:
    print("[ok] No unused Button import found in src/App.tsx")
app_path.write_text(app)

header_path = root / "src/components/layout/SiteHeader.tsx"
header = header_path.read_text()
old_import = 'import { useEffect, useState } from "react";'
new_import = 'import { useState } from "react";'
if old_import in header:
    header = header.replace(old_import, new_import, 1)
    print("[fix] Removed the unused useEffect import from SiteHeader.tsx")
elif new_import in header:
    print("[ok] SiteHeader.tsx already imports only useState")
else:
    raise SystemExit("[error] Could not identify the React hook import in SiteHeader.tsx; no further edits made.")
header_path.write_text(header)
PY

cd "$PROJECT_DIR"

# Confirm the two exact problems have gone before running the full quality checks.
if grep -nF 'import { Button } from "@/components/ui/button";' src/App.tsx; then
  fail "The unused Button import remains in src/App.tsx."
fi
if grep -nF 'import { useEffect, useState } from "react";' src/components/layout/SiteHeader.tsx; then
  fail "The unused useEffect import remains in SiteHeader.tsx."
fi

run_check() {
  local label="$1"
  shift
  log check "$label"
  "$@" || fail "$label failed. The file backup is available at: $BACKUP_DIR"
  log ok "$label passed"
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test -- --run
run_check "ESLint" npm run lint
run_check "Production build" npm run build

log ok "Import fixes and all configured checks completed successfully."
log info "Project: $PROJECT_DIR"
log info "Backup:  $BACKUP_DIR"
