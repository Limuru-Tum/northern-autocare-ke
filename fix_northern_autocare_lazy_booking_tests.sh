#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/northern-autocare-lazy-test-backup-$STAMP}"
SETUP_FILE="src/test/setup.ts"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" ]] || fail "package.json not found in $PROJECT_DIR"
[[ -f "$PROJECT_DIR/vite.config.ts" ]] || fail "vite.config.ts not found; no changes made."
[[ -f "$PROJECT_DIR/src/components/booking/DeferredAppointmentForm.tsx" ]] || fail "DeferredAppointmentForm.tsx not found; no changes made."
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."

mkdir -p "$BACKUP_DIR/$(dirname "$SETUP_FILE")"
if [[ -f "$PROJECT_DIR/$SETUP_FILE" ]]; then
  cp -p "$PROJECT_DIR/$SETUP_FILE" "$BACKUP_DIR/$SETUP_FILE"
else
  fail "$SETUP_FILE not found. I won't guess which file Vitest loads. No changes made."
fi
cp -p "$PROJECT_DIR/vite.config.ts" "$BACKUP_DIR/vite.config.ts"
log backup "Saved test setup and Vitest config outside project: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
setup_path = root / "src/test/setup.ts"
vite_path = root / "vite.config.ts"
setup = setup_path.read_text()
vite = vite_path.read_text()

if "./src/test/setup.ts" not in vite and "src/test/setup.ts" not in vite:
    raise SystemExit("[error] vite.config.ts does not appear to load src/test/setup.ts. No changes made.")

marker = "// NORTHERN_AUTOCARE_INTERSECTION_OBSERVER_TEST_MOCK"
if marker in setup:
    print("[ok] IntersectionObserver test mock already exists; no duplicate added.")
    raise SystemExit(0)

mock = r'''

// NORTHERN_AUTOCARE_INTERSECTION_OBSERVER_TEST_MOCK
// JSDOM has no real viewport. Treat observed targets as approaching the viewport
// so tests exercise the lazily loaded booking form deterministically. This is test-only;
// production browsers continue to use their native IntersectionObserver.
class NorthernAutocareTestIntersectionObserver {
  private readonly callback: IntersectionObserverCallback;
  readonly root: Element | Document | null = null;
  readonly rootMargin: string;
  readonly thresholds: ReadonlyArray<number>;

  constructor(callback: IntersectionObserverCallback, options: IntersectionObserverInit = {}) {
    this.callback = callback;
    this.rootMargin = options.rootMargin ?? "0px";
    const threshold = options.threshold ?? 0;
    this.thresholds = Array.isArray(threshold) ? threshold : [threshold];
  }

  observe(target: Element): void {
    const rect = target.getBoundingClientRect();
    const entry: IntersectionObserverEntry = {
      time: 0,
      target,
      rootBounds: null,
      boundingClientRect: rect,
      intersectionRect: rect,
      isIntersecting: true,
      intersectionRatio: 1,
    };
    this.callback([entry], this as unknown as IntersectionObserver);
  }

  unobserve(_target: Element): void {}
  disconnect(): void {}
  takeRecords(): IntersectionObserverEntry[] { return []; }
}

Object.defineProperty(globalThis, "IntersectionObserver", {
  configurable: true,
  writable: true,
  value: NorthernAutocareTestIntersectionObserver,
});
'''

# Avoid corrupting the file if it doesn't look like a TypeScript test setup module.
if not setup.strip():
    setup = ""
setup_path.write_text(setup.rstrip() + mock + "\n")
print("[fix] Added deterministic IntersectionObserver behavior for Vitest/JSDOM")
print("[info] Production lazy-loading logic is unchanged; this only affects the test setup")
PY

cd "$PROJECT_DIR"
run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then log ok "$label passed"; else fail "$label failed. Current files are backed up at: $BACKUP_DIR"; fi
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "Lint" npm run lint
run_check "Production build" npm run build
log done "Lazy-booking test environment repaired. Backup: $BACKUP_DIR"
