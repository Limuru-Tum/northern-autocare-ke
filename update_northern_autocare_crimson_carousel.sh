#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.repair-backups/crimson-carousel-$STAMP"

log() { printf '\033[0;36m[%s]\033[0m %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
for file in src/index.css src/App.tsx src/components/home/HeroCarousel.tsx src/components/ui/button.tsx src/App.test.tsx index.html package.json; do
  [[ -f "$PROJECT_DIR/$file" ]] || fail "Expected file missing: $PROJECT_DIR/$file. No files were changed."
done
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required for safe file updates."

mkdir -p "$BACKUP_DIR"
for file in src/index.css src/App.tsx src/components/home/HeroCarousel.tsx src/components/ui/button.tsx src/App.test.tsx index.html; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
log backup "Backed up files to $BACKUP_DIR"

cd "$PROJECT_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])

# Use a consistent crimson palette throughout the existing design tokens and CSS.
css_path = root / "src/index.css"
css = css_path.read_text()
replacements = {
    "#f0a52b": "#c8102e",
    "#b86b0e": "#9f1239",
    "#ffb63d": "#e11d48",
    "#f4c16b": "#ff9aaa",
    "rgb(240 165 43 /": "rgb(200 16 46 /",
}
for old, new in replacements.items():
    css = css.replace(old, new)

# Strong contrast for solid crimson surfaces and text placed over dark workshop imagery.
css = css.replace(
    ".button-amber { background: var(--na-amber); color: #191b1e;",
    ".button-amber { background: var(--na-amber); color: #ffffff;",
)
css = css.replace(
    ".carousel-arrow:hover, .carousel-pause:hover { color: var(--na-ink);",
    ".carousel-arrow:hover, .carousel-pause:hover { color: #ffffff;",
)
css = css.replace(
    ".ribbon-inner > span { font-size: 12px; font-weight: 800; letter-spacing: .02em; }",
    ".ribbon-inner > span { color: #ffffff; font-size: 12px; font-weight: 800; letter-spacing: .02em; }",
)
css = css.replace("color: #29251d; }", "color: #ffffff; }", 1)
css = css.replace(
    ".closing-inner .section-kicker { margin: 0; color: #4d3514;",
    ".closing-inner .section-kicker { margin: 0; color: #fff1f2;",
)
css = css.replace(
    ".closing-inner h2 { margin: 6px 0 0;",
    ".closing-inner h2 { color: #ffffff; margin: 6px 0 0;",
)
css = css.replace(
    ".about-copy h2 span, .process-intro h2 span, .booking-aside h2 span { color: var(--na-amber); }",
    ".about-copy h2 span, .booking-aside h2 span { color: #ff7186; }\n.process-intro h2 span { color: var(--na-amber); }",
)
css = css.replace(
    ".point-check { display: grid; place-items: center; flex: 0 0 23px; width: 23px; height: 23px; border: 1px solid rgb(200 16 46 / 53%); border-radius: 50%; color: var(--na-amber); }",
    ".point-check { display: grid; place-items: center; flex: 0 0 23px; width: 23px; height: 23px; border: 1px solid rgb(255 113 134 / 65%); border-radius: 50%; color: #ff7186; }",
)
css = css.replace(
    ".contact-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border: 1px solid rgb(255 255 255 / 13%); border-radius: 13px; color: var(--na-amber); }",
    ".contact-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border: 1px solid rgb(255 255 255 / 13%); border-radius: 13px; color: #ff7186; }",
)
css = css.replace("a.contact-detail:hover strong { color: var(--na-amber); }", "a.contact-detail:hover strong { color: #ff7186; }")
css = css.replace(".booking-note svg { flex: 0 0 auto; color: var(--na-amber); }", ".booking-note svg { flex: 0 0 auto; color: #ff7186; }")
css = css.replace(".brand-footer .brand-copy b { color: var(--na-amber); }", ".brand-footer .brand-copy b { color: #ff7186; }")
css = css.replace(".footer-links a:hover { color: var(--na-amber); }", ".footer-links a:hover { color: #ff7186; }")
css = css.replace(".footer-bottom a:hover { color: var(--na-amber); }", ".footer-bottom a:hover { color: #ff7186; }")
css = css.replace(".vehicle-card:hover { border-color: rgb(184 107 14 / 35%);", ".vehicle-card:hover { border-color: rgb(200 16 46 / 35%);")
css = css.replace(".vehicle-icon { display: grid; place-items: center; width: 48px; height: 48px; background: #f1dfc1; color: #5d3c15; border-radius: 14px; }", ".vehicle-icon { display: grid; place-items: center; width: 48px; height: 48px; background: #fde7ec; color: #9f1239; border-radius: 14px; }")
css = css.replace(".process-arrow { color: #a86c1d; }", ".process-arrow { color: #9f1239; }")
css = css.replace(".stamp-icon { display: grid; place-items: center; width: 37px; height: 37px; border-radius: 9px; background: var(--na-amber); }", ".stamp-icon { display: grid; place-items: center; width: 37px; height: 37px; border-radius: 9px; background: var(--na-amber); color: #ffffff; }")
css = css.replace(".about-image-caption { position: absolute; right: 22px; bottom: 13px; z-index: 2; display: flex; align-items: center; gap: 12px; color: #211f1b;", ".about-image-caption { position: absolute; right: 22px; bottom: 13px; z-index: 2; display: flex; align-items: center; gap: 12px; color: #ffffff;")
css = css.replace(".hero-index-watermark span { color: rgb(200 16 46 / 80%); }", ".hero-index-watermark span { color: rgb(255 113 134 / 90%); }")
css = css.replace(
    ".closing-icon { display: grid; place-items: center; flex: 0 0 52px; width: 52px; height: 52px;",
    ".closing-icon { display: grid; place-items: center; flex: 0 0 52px; width: 52px; height: 52px; color: #ffffff;",
)
# The main headline and small icons are used on dark surfaces, so use a brighter crimson tint there.
css = css.replace(".brand-mark { display: grid; place-items: center; width: 43px; height: 43px; color: var(--na-amber);",
                  ".brand-mark { display: grid; place-items: center; width: 43px; height: 43px; color: #ff7186;")
css = css.replace(".utility-item svg { color: var(--na-amber); }", ".utility-item svg { color: #ff7186; }")
css = css.replace(".eyebrow-light { color: #ff9aaa; }", ".eyebrow-light { color: #ffb4c0; }")
css = css.replace(".hero h1 span { color: var(--na-amber); }", ".hero h1 span { color: #ff7186; }")
css = css.replace(".hero-feature-icon { display: grid; place-items: center; width: 31px; height: 31px; border: 1px solid rgb(255 255 255 / 20%); border-radius: 50%; color: var(--na-amber); }",
                  ".hero-feature-icon { display: grid; place-items: center; width: 31px; height: 31px; border: 1px solid rgb(255 255 255 / 20%); border-radius: 50%; color: #ff7186; }")
css = css.replace(".service-icon { display: grid; place-items: center; width: 48px; height: 48px; border-radius: 14px; background: var(--na-graphite); color: var(--na-amber); }",
                  ".service-icon { display: grid; place-items: center; width: 48px; height: 48px; border-radius: 14px; background: var(--na-graphite); color: #ff7186; }")
css = css.replace(".booking-heading-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border-radius: 12px; background: var(--na-graphite); color: var(--na-amber); }",
                  ".booking-heading-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border-radius: 12px; background: var(--na-graphite); color: #ff7186; }")
# Ensure the cursor ambience stays in a crimson family and remains perceptible over both light and dark sections.
css = css.replace(
    "opacity: .22; background: radial-gradient(420px circle at var(--cursor-x) var(--cursor-y), color-mix(in srgb, var(--cursor-accent) 25%, transparent), transparent 68%); transition: opacity .3s ease, background-color .5s ease; mix-blend-mode: multiply;",
    "opacity: .30; background: radial-gradient(460px circle at var(--cursor-x) var(--cursor-y), color-mix(in srgb, var(--cursor-accent) 30%, transparent), transparent 70%); transition: opacity .3s ease, background-color .5s ease; mix-blend-mode: soft-light;",
)
# Explicit stacking guarantees the background images and overlays cannot block text or controls.
css = css.replace(".hero-media { overflow: hidden; }", ".hero-media { z-index: 0; overflow: hidden; }")
css = css.replace(".hero-container { z-index: 3;", ".hero-container { position: relative; z-index: 3;")
css = css.replace(".hero-overlay { background:", ".hero-overlay { z-index: 1; pointer-events: none; background:")
css = css.replace(".hero-grid { opacity:", ".hero-grid { z-index: 2; pointer-events: none; opacity:")
css = css.replace("  .carousel-pause { display: none; }", "  .carousel-pause { display: grid; width: 30px; height: 30px; }")
# Rename internal design tokens to match the chosen brand palette instead of retaining the previous amber naming.
css = css.replace("--na-amber-deep", "--na-crimson-deep").replace("--na-amber", "--na-crimson")
css_path.write_text(css)
print("[fix] Applied crimson brand palette and stronger contrast to src/index.css")

# Keep the pointer colour movement subtle, but within crimson / cherry-red hues rather than cycling through unrelated colours.
app_path = root / "src/App.tsx"
app = app_path.read_text()
old_cursor = '''const hue = Math.round(28 + x * 145);
    const root = document.documentElement;
    root.style.setProperty("--cursor-x", `${event.clientX}px`);
    root.style.setProperty("--cursor-y", `${event.clientY}px`);
    root.style.setProperty("--cursor-accent", `hsl(${hue} 76% 54%)`);'''
new_cursor = '''const hue = Math.round(345 + x * 15);
    const saturation = Math.round(74 + x * 10);
    const lightness = Math.round(47 + x * 8);
    const root = document.documentElement;
    root.style.setProperty("--cursor-x", `${event.clientX}px`);
    root.style.setProperty("--cursor-y", `${event.clientY}px`);
    root.style.setProperty("--cursor-accent", `hsl(${hue} ${saturation}% ${lightness}%)`);'''
if old_cursor in app:
    app = app.replace(old_cursor, new_cursor, 1)
    print("[fix] Restricted cursor-reactive colour changes to elegant crimson shades")
elif "Math.round(345 + x * 15)" in app:
    print("[ok] Cursor ambience already uses the crimson hue range")
else:
    raise SystemExit("[error] Could not identify the cursor colour code in src/App.tsx; no carousel changes were written after this point.")
app_path.write_text(app)

# The crimson is the accessible foreground colour for filled call-to-action buttons.
button_path = root / "src/components/ui/button.tsx"
button = button_path.read_text()
button = button.replace("--na-amber", "--na-crimson")
button = button.replace('amber: "bg-[var(--na-crimson)] text-[#1b1d20] hover:opacity-90",',
                        'amber: "bg-[var(--na-crimson)] text-white hover:opacity-90",')
button_path.write_text(button)

# Match browser chrome colour to the brand.
html_path = root / "index.html"
html = html_path.read_text().replace('<meta name="theme-color" content="#1b1d20" />',
                                     '<meta name="theme-color" content="#c8102e" />')
html_path.write_text(html)
print("[fix] Updated button foreground and browser theme colour")
PY

cat > src/components/home/HeroCarousel.tsx <<'TSX_EOF'
import { useEffect, useRef, useState } from "react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { ArrowDown, ArrowRight, ChevronLeft, ChevronRight, Pause, Play, ScanSearch } from "lucide-react";

const slides = [
  {
    id: "precision",
    eyebrow: "AUTOMOTIVE CARE · LODWAR",
    title: ["Precision care.", "Confidence on every road."],
    description: "From computerized diagnostics to routine servicing, give your vehicle the thoughtful attention it deserves.",
    image: "https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=2200&q=88",
    imageAlt: "Vehicle engine being inspected in an automotive workshop",
    tag: "Diagnostics-led care",
  },
  {
    id: "engine",
    eyebrow: "ENGINE CARE · BUILT AROUND YOUR VEHICLE",
    title: ["When performance", "matters most."],
    description: "Engine overhauls, V6 and diesel engine assembly, and mechanical repair support for the miles ahead.",
    image: "https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=2200&q=88",
    imageAlt: "Automotive mechanic working on a vehicle in a workshop",
    tag: "Engine & mechanical work",
  },
  {
    id: "fleet",
    eyebrow: "FOR EVERYDAY DRIVES AND WORKING FLEETS",
    title: ["Keep your work", "moving forward."],
    description: "Service support for saloon cars, 4x4 pickups, and commercial vans including Toyota Hiace matatus.",
    image: "https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=2200&q=88",
    imageAlt: "Modern vehicle ready for the road",
    tag: "Cars · Pickups · Commercial vans",
  },
] as const;

const AUTOPLAY_DELAY = 6500;

function prefersReducedMotionOnLoad() {
  return typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

export function HeroCarousel() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [paused, setPaused] = useState(prefersReducedMotionOnLoad);
  const [focused, setFocused] = useState(false);
  const pointerInteraction = useRef(false);
  const [documentVisible, setDocumentVisible] = useState(
    () => typeof document === "undefined" || document.visibilityState === "visible",
  );
  const reducedMotion = useReducedMotion();
  const activeSlide = slides[activeIndex];

  // Pause when the visitor switches to another tab; resume when they return if playback is enabled.
  useEffect(() => {
    const handleVisibilityChange = () => setDocumentVisible(document.visibilityState === "visible");
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, []);

  // Respect a newly enabled reduced-motion preference by stopping automatic movement.
  useEffect(() => {
    const mediaQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    const handleMotionPreference = (event: MediaQueryListEvent) => {
      if (event.matches) setPaused(true);
    };
    // Older browsers and lightweight test environments may only expose addListener/removeListener.
    if (typeof mediaQuery.addEventListener === "function") {
      mediaQuery.addEventListener("change", handleMotionPreference);
      return () => mediaQuery.removeEventListener("change", handleMotionPreference);
    }
    mediaQuery.addListener?.(handleMotionPreference);
    return () => mediaQuery.removeListener?.(handleMotionPreference);
  }, []);

  // Preload hero photos so manual and automatic slide changes don't reveal a blank frame on slower connections.
  useEffect(() => {
    const images = slides.map((slide) => {
      const image = new Image();
      image.decoding = "async";
      image.src = slide.image;
      return image;
    });
    return () => {
      images.forEach((image) => image.removeAttribute("src"));
    };
  }, []);

  useEffect(() => {
    if (paused || focused || !documentVisible) return;
    const timer = window.setTimeout(() => {
      setActiveIndex((current) => (current + 1) % slides.length);
    }, AUTOPLAY_DELAY);
    return () => window.clearTimeout(timer);
  }, [activeIndex, paused, focused, documentVisible]);

  const previous = () => setActiveIndex((current) => (current - 1 + slides.length) % slides.length);
  const next = () => setActiveIndex((current) => (current + 1) % slides.length);
  const goToSlide = (index: number) => setActiveIndex(index);

  return (
    <section
      className="hero"
      aria-label="Featured automotive services"
      onPointerDownCapture={() => {
        pointerInteraction.current = true;
        setFocused(false);
        window.setTimeout(() => { pointerInteraction.current = false; }, 0);
      }}
      onFocusCapture={() => {
        // Keyboard focus pauses rotation; clicking the controls with a pointer should still allow playback.
        if (!pointerInteraction.current) setFocused(true);
      }}
      onBlurCapture={(event) => {
        const nextTarget = event.relatedTarget;
        if (!(nextTarget instanceof Node) || !event.currentTarget.contains(nextTarget)) setFocused(false);
      }}
    >
      <div className="hero-media" aria-hidden="true">
        <AnimatePresence initial={false} mode="sync">
          <motion.img
            key={activeSlide.id}
            className="hero-image"
            src={activeSlide.image}
            alt=""
            decoding="async"
            initial={{ opacity: 0, scale: reducedMotion ? 1 : 1.035 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reducedMotion ? 0.01 : 0.75, ease: [0.22, 1, 0.36, 1] }}
            fetchPriority="high"
          />
        </AnimatePresence>
        <div className="hero-overlay" />
        <div className="hero-grid" />
      </div>

      <div className="container hero-container">
        <div className="hero-copy-wrap">
          <AnimatePresence mode="sync" initial={false}>
            <motion.div
              key={activeSlide.id}
              className="hero-copy"
              initial={{ opacity: 0, y: reducedMotion ? 0 : 14 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: reducedMotion ? 0 : -8 }}
              transition={{ duration: reducedMotion ? 0.01 : 0.35, ease: "easeOut" }}
            >
              <div className="eyebrow eyebrow-light"><span className="eyebrow-dot" />{activeSlide.eyebrow}</div>
              <h1>{activeSlide.title[0]}<br /><span>{activeSlide.title[1]}</span></h1>
              <p className="hero-description">{activeSlide.description}</p>
              <div className="hero-actions">
                <a className="button button-amber button-large" href="#booking">Request an appointment <ArrowRight aria-hidden="true" size={18} /></a>
                <a className="hero-text-link" href="#services">Explore our services <ArrowDown aria-hidden="true" size={16} /></a>
              </div>
              <div className="hero-feature"><span className="hero-feature-icon"><ScanSearch aria-hidden="true" size={17} /></span><span>{activeSlide.tag}</span></div>
            </motion.div>
          </AnimatePresence>
        </div>

        <div className="hero-bottom-row">
          <div className="hero-location"><span className="location-line" /><span>Serving Lodwar & surrounding journeys</span></div>
          <div className="carousel-controls" role="group" aria-label="Hero carousel controls">
            <span className="carousel-count" aria-label={`Slide ${activeIndex + 1} of ${slides.length}`}><strong>0{activeIndex + 1}</strong><span>/</span>0{slides.length}</span>
            <div className="carousel-progress" aria-label="Choose a featured slide">
              {slides.map((slide, index) => (
                <button
                  type="button"
                  key={slide.id}
                  className={`progress-segment${index === activeIndex ? " progress-active" : ""}`}
                  aria-label={`Show slide ${index + 1}: ${slide.title.join(" ")}`}
                  aria-current={index === activeIndex ? "true" : undefined}
                  onClick={() => goToSlide(index)}
                ><span /></button>
              ))}
            </div>
            <button type="button" className="carousel-arrow" aria-label="Previous slide" onClick={previous}><ChevronLeft size={19} aria-hidden="true" /></button>
            <button type="button" className="carousel-arrow" aria-label="Next slide" onClick={next}><ChevronRight size={19} aria-hidden="true" /></button>
            <button
              type="button"
              className="carousel-pause"
              aria-label={paused ? "Play automatic slides" : "Pause automatic slides"}
              aria-pressed={paused}
              onClick={() => setPaused((value) => !value)}
            >{paused ? <Play size={15} aria-hidden="true" /> : <Pause size={15} aria-hidden="true" />}</button>
          </div>
        </div>
      </div>
      <div className="hero-index-watermark" aria-hidden="true">N<span>A</span> / KE</div>
    </section>
  );
}
TSX_EOF
log fix "Rebuilt carousel autoplay, responsive controls, image preloading, keyboard-focus pause and tab visibility behaviour"

# Add a regression test for the Next control without replacing the user's current test suite.
python3 - "$PROJECT_DIR/src/App.test.tsx" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if 'fireEvent' not in s.splitlines()[0:5]:
    s = s.replace('import { render, screen } from "@testing-library/react";',
                  'import { fireEvent, render, screen } from "@testing-library/react";', 1)
if 'moves to the next hero slide' not in s:
    insertion = '''

  it("moves to the next hero slide with the carousel controls", async () => {
    render(<App />);
    fireEvent.click(screen.getByRole("button", { name: /Next slide/i }));
    expect(await screen.findByRole("heading", { name: /When performance matters most/i })).toBeInTheDocument();
  });'''
    s = s.replace('\n});\n', insertion + '\n});\n', 1)
    p.write_text(s)
    print("[test] Added a hero carousel navigation regression test")
else:
    print("[ok] Hero carousel navigation regression test already exists")
PY

# Check the key theme changes before running the full project checks.
grep -q -- '--na-crimson: #c8102e' src/index.css || fail "The crimson design token was not applied. Restore from $BACKUP_DIR/src/index.css if needed."
grep -q 'Math.round(345 + x \* 15)' src/App.tsx || fail "The cursor colour update was not applied. Restore from $BACKUP_DIR/src/App.tsx if needed."

run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then log ok "$label passed"; else fail "$label failed. Backups are available at: $BACKUP_DIR"; fi
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "Lint" npm run lint
run_check "Production build" npm run build

log ok "Crimson theme and hero carousel repair completed."
printf '\nProject: %s\nBackup:  %s\n' "$PROJECT_DIR" "$BACKUP_DIR"
printf '\nIf Vite is already running, refresh the browser. Otherwise run:\n  cd "%s"\n  npm run dev\n' "$PROJECT_DIR"
