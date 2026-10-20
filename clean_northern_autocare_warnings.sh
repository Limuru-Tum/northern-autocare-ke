#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/Desktop/northern-autocare-ke-quality-backup-$TIMESTAMP"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1"; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" ]] || fail "package.json is missing from $PROJECT_DIR"
[[ -f "$PROJECT_DIR/src/App.tsx" ]] || fail "src/App.tsx is missing"
[[ -f "$PROJECT_DIR/src/components/ui/button.tsx" ]] || fail "src/components/ui/button.tsx is missing"

mkdir -p "$BACKUP_DIR/src/components/ui"
cp "$PROJECT_DIR/package.json" "$BACKUP_DIR/package.json"
cp "$PROJECT_DIR/src/App.tsx" "$BACKUP_DIR/src/App.tsx"
cp "$PROJECT_DIR/src/components/ui/button.tsx" "$BACKUP_DIR/src/components/ui/button.tsx"
log backup "Saved files outside the project at $BACKUP_DIR"

node --input-type=module - "$PROJECT_DIR/package.json" <<'NODE'
import fs from 'node:fs';
const path = process.argv[2];
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
pkg.scripts ??= {};
if (typeof pkg.scripts.lint !== 'string') {
  throw new Error('No npm lint script found; refusing to guess how to change it.');
}
// Keep Oxlint focused on application source instead of archived backups and generated files.
pkg.scripts.lint = pkg.scripts.lint
  .replace(/\boxlint\s+\.\s*$/, 'oxlint src')
  .replace(/\boxlint\s+src\s*$/, 'oxlint src');
if (!pkg.scripts.lint.includes('oxlint src')) {
  throw new Error(`Unexpected lint script format: ${pkg.scripts.lint}`);
}
fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + '\n');
NODE
log fix "Limited linting to src so hidden/local repair backups aren't linted"

python3 - "$PROJECT_DIR/src/App.tsx" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s = p.read_text()
old = 'new Date().getFullYear()'
if old in s:
    constant_line = 'const CURRENT_YEAR = new Date().getFullYear();'
    already_has_constant = constant_line in s
    if already_has_constant:
        # Protect the module-level definition while updating render-time expressions.
        s = s.replace(constant_line, '__CURRENT_YEAR_CONSTANT__', 1)
    s = s.replace(old, 'CURRENT_YEAR')
    if already_has_constant:
        s = s.replace('__CURRENT_YEAR_CONSTANT__', constant_line, 1)
    else:
        # Place the stable year constant immediately before the App component declaration.
        pattern = re.compile(r'(?m)^(?:export\s+default\s+)?function\s+App\b|^(?:export\s+)?const\s+App\s*=')
        match = pattern.search(s)
        if not match:
            raise SystemExit('Could not safely locate the App component declaration; no App.tsx changes made.')
        s = s[:match.start()] + constant_line + '\n\n' + s[match.start():]
    p.write_text(s)
    print('[fix] Moved footer year calculation outside React render')
else:
    print('[skip] Footer year expression not found; no date change needed')
PY

python3 - "$PROJECT_DIR/src/components/ui/button.tsx" "$PROJECT_DIR/src" <<'PY'
from pathlib import Path
import sys
button_file = Path(sys.argv[1])
src_dir = Path(sys.argv[2])
s = button_file.read_text()
# Only remove the helper's public export if nothing else in src imports/references it.
external_refs = []
for p in src_dir.rglob('*'):
    if not p.is_file() or p.suffix not in {'.ts', '.tsx', '.js', '.jsx'} or p.resolve() == button_file.resolve():
        continue
    try:
        content = p.read_text()
    except UnicodeDecodeError:
        continue
    if 'buttonVariants' in content:
        external_refs.append(str(p))
if external_refs:
    print('[skip] buttonVariants is used elsewhere; preserved export in button.tsx')
else:
    updated = s.replace('export { Button, buttonVariants };', 'export { Button };')
    if updated != s:
        button_file.write_text(updated)
        print('[fix] Removed unused buttonVariants export to satisfy React fast-refresh lint')
    else:
        print('[skip] Expected button export line not found; no button.tsx change made')
PY

cd "$PROJECT_DIR"
for check in typecheck test lint build; do
  log check "npm run $check"
  npm run "$check" || fail "npm run $check failed. Backups: $BACKUP_DIR"
done

log done "Lint cleanup and verification completed. Backup: $BACKUP_DIR"
