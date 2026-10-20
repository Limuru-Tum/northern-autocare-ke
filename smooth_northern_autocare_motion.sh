#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/Desktop/northern-autocare-ke-motion-backup-$STAMP"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
for file in src/App.tsx src/index.css src/components/home/HeroCarousel.tsx package.json; do
  [[ -f "$PROJECT_DIR/$file" ]] || fail "Required file missing: $PROJECT_DIR/$file. No changes made."
done
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."

mkdir -p "$BACKUP_DIR"
for file in src/App.tsx src/index.css src/components/home/HeroCarousel.tsx package.json; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
log backup "Saved original files outside the project: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
app_path = root / "src/App.tsx"
css_path = root / "src/index.css"
carousel_path = root / "src/components/home/HeroCarousel.tsx"
app = app_path.read_text()
css = css_path.read_text()
carousel = carousel_path.read_text()

# --- Cursor-reactive background ---
# Replace the complete current callback, so both cursor coordinates and crimson shade update together.
callback_pattern = re.compile(
    r"  const handlePointerMove = useCallback\(\(event: PointerEvent<HTMLDivElement>\) => \{.*?\n  \}, \[reducedMotion\]\);",
    re.S,
)
callback_match = callback_pattern.search(app)
if not callback_match:
    raise SystemExit("[error] Could not safely identify App.tsx handlePointerMove callback; no application files changed.")
if "onPointerMove={handlePointerMove}" not in app:
    raise SystemExit("[error] App.tsx does not attach handlePointerMove to the site shell; no application files changed.")
new_callback = '''  const handlePointerMove = useCallback((event: PointerEvent<HTMLDivElement>) => {
    // Keep this effect for a real mouse pointer only; do not simulate cursor movement on touch.
    if (event.pointerType !== "mouse" || reducedMotion || typeof window === "undefined") return;

    const x = Math.max(0, Math.min(1, event.clientX / window.innerWidth));
    const y = Math.max(0, Math.min(1, event.clientY / window.innerHeight));
    // Move through a deliberately narrow crimson-to-cherry palette based on both axes.
    const hue = Math.round(342 + x * 15 + (1 - y) * 2);
    const saturation = Math.round(82 + x * 10);
    const lightness = Math.round(45 + (1 - y) * 8);
    const root = document.documentElement;
    root.style.setProperty("--cursor-x", `${event.clientX}px`);
    root.style.setProperty("--cursor-y", `${event.clientY}px`);
    root.style.setProperty("--cursor-accent", `hsl(${hue % 360} ${saturation}% ${lightness}%)`);
  }, [reducedMotion]);'''
app = app[:callback_match.start()] + new_callback + app[callback_match.end():]
print("[fix] Cursor position and crimson colour now respond to both pointer axes")

# --- Smooth, non-jarring hero image crossfade ---
old_image_motion = '''            initial={{ opacity: 0, scale: reducedMotion ? 1 : 1.035 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reducedMotion ? 0.01 : 0.75, ease: [0.22, 1, 0.36, 1] }}'''
new_image_motion = '''            initial={{ opacity: 0, scale: reducedMotion ? 1 : 1.012 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reducedMotion ? 0.01 : 1.12, ease: [0.22, 1, 0.36, 1] }}'''
if old_image_motion in carousel:
    carousel = carousel.replace(old_image_motion, new_image_motion, 1)
elif "duration: reducedMotion ? 0.01 : 1.12" in carousel and "scale: reducedMotion ? 1 : 1.012" in carousel:
    print("[ok] Hero image already uses the smooth crossfade timing")
else:
    raise SystemExit("[error] Could not identify the current hero image animation; no application files changed.")

# Let the old copy fade out briefly before the new copy enters, avoiding overlapping headlines.
old_copy_presence = '''          <AnimatePresence mode="sync" initial={false}>
            <motion.div
              key={activeSlide.id}
              className="hero-copy"'''
new_copy_presence = '''          <AnimatePresence mode="wait" initial={false}>
            <motion.div
              key={activeSlide.id}
              className="hero-copy"'''
if old_copy_presence in carousel:
    carousel = carousel.replace(old_copy_presence, new_copy_presence, 1)
elif new_copy_presence not in carousel:
    raise SystemExit("[error] Could not identify the hero copy AnimatePresence block; no application files changed.")

old_copy_motion = '''              initial={{ opacity: 0, y: reducedMotion ? 0 : 14 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: reducedMotion ? 0 : -8 }}
              transition={{ duration: reducedMotion ? 0.01 : 0.35, ease: "easeOut" }}'''
new_copy_motion = '''              initial={{ opacity: 0, y: reducedMotion ? 0 : 7 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{
                opacity: 0,
                y: reducedMotion ? 0 : -4,
                transition: { duration: reducedMotion ? 0.01 : 0.2, ease: "easeIn" },
              }}
              transition={{ duration: reducedMotion ? 0.01 : 0.46, ease: [0.16, 1, 0.3, 1] }}'''
if old_copy_motion in carousel:
    carousel = carousel.replace(old_copy_motion, new_copy_motion, 1)
elif "duration: reducedMotion ? 0.01 : 0.46" not in carousel:
    raise SystemExit("[error] Could not identify the hero copy motion settings; no application files changed.")

# --- Non-layout-shifting stacking and cursor ambience ---
marker = "/* Northern Autocare KE — smooth silent motion and cursor ambience */"
if marker not in css:
    css += r'''

/* Northern Autocare KE — smooth silent motion and cursor ambience */
/* A soft, visible crimson glow follows the mouse without capturing pointer input. */
.cursor-ambient {
  position: fixed;
  inset: 0;
  z-index: 40;
  pointer-events: none;
  opacity: .82;
  background: radial-gradient(
    560px circle at var(--cursor-x, 50vw) var(--cursor-y, 35vh),
    color-mix(in srgb, var(--cursor-accent, #c8102e) 38%, transparent) 0%,
    color-mix(in srgb, var(--cursor-accent, #c8102e) 19%, transparent) 30%,
    transparent 72%
  );
  mix-blend-mode: soft-light;
  transition: opacity .28s ease;
  will-change: background;
}

/* Keep all hero layers stable while Motion fades the outgoing and incoming images. */
.hero-media { z-index: 0; isolation: isolate; overflow: hidden; }
.hero-image { z-index: 0; will-change: opacity, transform; backface-visibility: hidden; transform-origin: center center; }
.hero-overlay { z-index: 1; pointer-events: none; }
.hero-grid { z-index: 2; pointer-events: none; }
.hero-container { position: relative; z-index: 3; }
.hero-copy-wrap { display: grid; align-items: start; }
.hero-copy { grid-area: 1 / 1; width: 100%; will-change: opacity, transform; }
.carousel-arrow, .carousel-pause, .progress-segment { touch-action: manipulation; }

@media (hover: none), (pointer: coarse) {
  .cursor-ambient { display: none !important; }
}
@media (prefers-reduced-motion: reduce) {
  .cursor-ambient { display: none !important; }
  .hero-image, .hero-copy { will-change: auto; }
}
'''
    print("[style] Added the stronger crimson cursor glow and stable hero layer styling")
else:
    print("[skip] Cursor ambience and smooth-motion layer already exists")

# Commit all staged text changes only after every replacement has passed its checks.
app_path.write_text(app)
carousel_path.write_text(carousel)
css_path.write_text(css)
print("[fix] Hero imagery now crossfades slowly; headline exits before the next enters")
PY

cd "$PROJECT_DIR"
run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then log ok "$label passed"; else fail "$label failed. Original files are backed up at: $BACKUP_DIR"; fi
}
run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "Lint" npm run lint
run_check "Production build" npm run build

log done "Smooth hero transitions and cursor-reactive crimson ambience applied."
printf '\nProject: %s\nBackup:  %s\n' "$PROJECT_DIR" "$BACKUP_DIR"
printf '\nRefresh the browser if Vite is already running. Otherwise run:\n  cd "%s"\n  npm run dev\n' "$PROJECT_DIR"
