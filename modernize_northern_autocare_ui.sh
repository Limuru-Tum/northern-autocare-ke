#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/Desktop/northern-autocare-ke-ui-backup-$STAMP"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
for file in package.json src/index.css src/App.tsx src/components/home/HeroCarousel.tsx index.html; do
  [[ -f "$PROJECT_DIR/$file" ]] || fail "Required file missing: $PROJECT_DIR/$file. No changes made."
done
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."

mkdir -p "$BACKUP_DIR"
for file in src/index.css index.html; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
log backup "Saved original stylesheet and HTML to: $BACKUP_DIR"

python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
css_path = root / "src/index.css"
html_path = root / "index.html"
css = css_path.read_text()
html = html_path.read_text()

# Fail before writing if this does not look like the intended Northern Autocare UI.
required_selectors = [".hero", ".services-grid", ".service-card", ".booking-card", ".site-header"]
missing = [selector for selector in required_selectors if selector not in css]
if missing:
    raise SystemExit("[error] Stylesheet structure differs from the expected app (missing: " + ", ".join(missing) + "). No styling changes written.")

# Load a refined typeface when online; system fallbacks keep the page usable offline.
font_marker = "fonts.googleapis.com/css2?family=Manrope"
if font_marker not in html:
    head_close = re.search(r"</head\s*>", html, re.I)
    if not head_close:
        raise SystemExit("[error] Could not locate </head> in index.html; no styling changes written.")
    font_links = '''\n    <link rel="preconnect" href="https://fonts.googleapis.com" />\n    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />\n    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet" />\n'''
    html = html[:head_close.start()] + font_links + html[head_close.start():]
    print("[design] Added Manrope and DM Sans with local system fallbacks")
else:
    print("[skip] Premium font links are already present")

marker = "/* Northern Autocare KE — modern crimson design system v2 */"
if marker not in css:
    polish = r'''

/* Northern Autocare KE — modern crimson design system v2 */
:root {
  --na-crimson: #c8102e;
  --na-crimson-deep: #9f1239;
  --na-crimson-bright: #e11d48;
  --na-crimson-soft: #ff8798;
  --na-ivory: #f7f7f9;
  --na-paper: #ffffff;
  --na-ink: #1c1b20;
  --na-graphite: #242329;
  --na-graphite-deep: #17151a;
  --na-line: rgb(31 27 32 / 10%);
  /* Compatibility aliases for any earlier components using the old token names. */
  --na-amber: var(--na-crimson);
  --na-amber-deep: var(--na-crimson-deep);
  --background: var(--na-ivory);
  --foreground: var(--na-ink);
}

html { scroll-behavior: smooth; scroll-padding-top: 96px; }
body {
  background: var(--na-ivory);
  color: var(--na-ink);
  font-family: "DM Sans", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-feature-settings: "ss01" on;
  line-height: 1.55;
}
:is(h1, h2, h3, h4, .brand-copy, .button) {
  font-family: "Manrope", "DM Sans", ui-sans-serif, system-ui, sans-serif;
}
::selection { background: rgb(200 16 46 / 82%); color: #fff; }
:focus-visible { outline: 3px solid #e11d48; outline-offset: 4px; }

.site-shell { background: var(--na-ivory); }
.container { width: min(1240px, calc(100% - 64px)); }
.utility-bar {
  background: linear-gradient(100deg, #19171c 0%, #2c1119 65%, #42101c 100%);
  color: rgb(255 255 255 / 75%);
}
.utility-inner { min-height: 35px; }
.utility-item svg { color: #ff8798; }
.site-header {
  background: rgb(255 255 255 / 91%);
  border-bottom: 1px solid rgb(30 20 25 / 8%);
  box-shadow: 0 8px 28px rgb(20 14 18 / 5%);
  backdrop-filter: blur(20px) saturate(145%);
}
.header-inner { min-height: 80px; }
.brand { gap: 12px; }
.brand-mark {
  width: 45px; height: 45px; border-radius: 14px;
  color: #fff;
  background: linear-gradient(145deg, #e11d48 0%, #c8102e 58%, #8f1235 100%);
  box-shadow: 0 8px 18px rgb(200 16 46 / 22%), inset 0 1px 0 rgb(255 255 255 / 28%);
}
.brand-copy strong { font-size: 14px; letter-spacing: .16em; }
.brand-copy span { color: #48464d; font-size: 9px; letter-spacing: .24em; }
.brand-copy b { color: var(--na-crimson); }
.desktop-nav { gap: clamp(16px, 2.6vw, 32px); }
.desktop-nav > a:not(.button) {
  position: relative;
  padding-block: 10px;
  color: #56525a;
  font-size: 12px;
  font-weight: 700;
}
.desktop-nav > a:not(.button)::after {
  position: absolute; right: 0; bottom: 3px; left: 0; height: 2px;
  border-radius: 999px; background: var(--na-crimson); content: "";
  transform: scaleX(0); transform-origin: left; transition: transform .22s ease;
}
.desktop-nav > a:not(.button):hover::after,
.desktop-nav > a:not(.button):focus-visible::after { transform: scaleX(1); }
.desktop-nav > a:not(.button):hover { color: var(--na-crimson-deep); }

.button {
  min-height: 47px; padding: 0 21px; border-radius: 11px;
  font-size: 12px; font-weight: 800; letter-spacing: -.01em;
  transition: transform .22s cubic-bezier(.2,.75,.25,1), box-shadow .22s ease, background .22s ease, border-color .22s ease;
}
.button:hover { transform: translateY(-2px); }
.button:active { transform: translateY(0) scale(.99); }
.button-dark {
  color: #fff; background: linear-gradient(135deg, #302c34 0%, #1c1a20 100%);
  box-shadow: 0 8px 18px rgb(20 16 20 / 13%);
}
.button-dark:hover { background: linear-gradient(135deg, #48404a 0%, #282329 100%); box-shadow: 0 12px 25px rgb(20 16 20 / 18%); }
.button-amber {
  color: #fff;
  background: linear-gradient(125deg, #e11d48 0%, #c8102e 52%, #9f1239 100%);
  box-shadow: 0 10px 24px rgb(200 16 46 / 26%), inset 0 1px 0 rgb(255 255 255 / 22%);
}
.button-amber:hover {
  color: #fff; background: linear-gradient(125deg, #ed3157 0%, #d41436 50%, #a5103b 100%);
  box-shadow: 0 14px 30px rgb(200 16 46 / 34%);
}
.button-large { min-height: 56px; padding-inline: 24px; }
.nav-book { border-radius: 10px; }
.menu-toggle { border-radius: 12px; transition: background .2s ease, border-color .2s ease, color .2s ease; }
.menu-toggle:hover { color: #fff; border-color: var(--na-crimson); background: var(--na-crimson); }

/* Hero: high contrast, restrained crimson atmosphere, readable content first. */
.hero {
  min-height: clamp(620px, 82svh, 800px);
  background: #19171c;
  isolation: isolate;
}
.hero-media { z-index: 0; isolation: isolate; }
.hero-image { filter: saturate(.86) contrast(1.04); }
.hero-overlay {
  z-index: 1; pointer-events: none;
  background:
    radial-gradient(ellipse at 80% 15%, rgb(200 16 46 / 23%) 0%, transparent 44%),
    linear-gradient(90deg, rgb(18 16 21 / 95%) 0%, rgb(22 17 23 / 85%) 38%, rgb(25 17 23 / 48%) 70%, rgb(17 15 20 / 24%) 100%),
    linear-gradient(0deg, rgb(13 12 16 / 72%) 0%, transparent 40%);
}
.hero-grid { z-index: 2; pointer-events: none; opacity: .13; background-size: 92px 92px; }
.hero-container { position: relative; z-index: 3; padding-top: clamp(70px, 9vh, 112px); padding-bottom: 30px; }
.hero-copy-wrap { width: min(790px, 78%); min-height: 410px; }
.hero h1 {
  max-width: 810px; margin-top: 25px;
  font-size: clamp(50px, 6.4vw, 86px); font-weight: 750;
  line-height: .99; letter-spacing: -.072em; text-wrap: balance;
}
.hero h1 span {
  color: #ff8798;
  text-shadow: 0 4px 30px rgb(200 16 46 / 18%);
}
.eyebrow { letter-spacing: .19em; }
.eyebrow-dot { background: #ff526f; box-shadow: 0 0 0 5px rgb(225 29 72 / 17%), 0 0 18px rgb(225 29 72 / 40%); }
.hero-description { max-width: 530px; color: rgb(255 255 255 / 80%); line-height: 1.86; }
.hero-actions { gap: 22px; }
.hero-feature-icon { color: #ff8798; border-color: rgb(255 135 152 / 38%); background: rgb(200 16 46 / 11%); }
.hero-location { color: rgb(255 255 255 / 70%); }
.location-line { background: #ff7186; }
.hero-index-watermark { color: rgb(255 255 255 / 20%); font-weight: 800; }
.hero-index-watermark span { color: #ff7186; }
.carousel-controls { gap: 9px; }
.carousel-arrow, .carousel-pause {
  width: 40px; height: 40px; border-radius: 50%;
  background: rgb(255 255 255 / 8%); border-color: rgb(255 255 255 / 30%);
  backdrop-filter: blur(14px); transition: background .2s ease, border-color .2s ease, transform .2s ease;
}
.carousel-arrow:hover, .carousel-pause:hover {
  color: #fff; border-color: var(--na-crimson); background: var(--na-crimson); transform: translateY(-1px);
}
.carousel-count { font-variant-numeric: tabular-nums; }
.carousel-count strong { color: #fff; }
.carousel-count span { color: #ff8798; }
.carousel-progress { gap: 6px; }
.progress-segment { width: 30px; }
.progress-segment span { border-radius: 99px; background: rgb(255 255 255 / 35%); }
.progress-segment.progress-active span { background: #ff7186; box-shadow: 0 0 10px rgb(255 113 134 / 35%); }

/* A high-contrast signature strip after the hero. */
.service-ribbon {
  position: relative; background: linear-gradient(100deg, #a70f2c 0%, #c8102e 52%, #8e1232 100%);
  color: #fff; box-shadow: inset 0 1px 0 rgb(255 255 255 / 14%);
}
.ribbon-inner { min-height: 76px; }
.ribbon-inner > span { color: #fff; font-size: 12px; letter-spacing: .015em; }
.ribbon-items { gap: clamp(13px, 2.3vw, 27px); }
.ribbon-items span { color: rgb(255 255 255 / 88%); font-size: 10px; }
.ribbon-items svg { color: #ffc0ca; }

/* Clearer hierarchy and separate, card-based service catalogue. */
.section { padding-block: clamp(78px, 8.5vw, 116px); }
.services-section { background: #f7f7f9; }
.section-heading { margin-bottom: 42px; }
.section-kicker { color: var(--na-crimson-deep); letter-spacing: .17em; }
.section-kicker::before {
  content: ""; display: inline-block; width: 24px; height: 2px; flex: 0 0 24px;
  border-radius: 99px; background: var(--na-crimson);
}
.section-heading h2, .about-copy h2, .process-intro h2, .booking-aside h2 {
  font-family: "Manrope", sans-serif; font-weight: 750; letter-spacing: -.06em;
}
.section-heading h2 span { color: #77717a; }
.section-lede { color: #696670; line-height: 1.9; }
.services-grid {
  gap: 17px; border: 0; align-items: stretch;
}
.service-card {
  position: relative; min-height: 282px; padding: 25px 25px 23px;
  border: 1px solid rgb(42 31 38 / 9%); border-radius: 18px;
  background: #fff; box-shadow: 0 5px 16px rgb(30 21 27 / 3%);
  overflow: hidden;
  transition: border-color .24s ease, background .24s ease, transform .24s ease, box-shadow .24s ease;
}
.service-card::after {
  content: ""; position: absolute; inset: auto 0 0; height: 3px;
  background: linear-gradient(90deg, #c8102e, #ff8798 55%, transparent);
  transform: scaleX(0); transform-origin: left; transition: transform .25s ease;
}
.service-card:hover, .service-card:focus-within {
  background: #fff; border-color: rgb(200 16 46 / 22%);
  box-shadow: 0 18px 42px rgb(37 19 27 / 9%); transform: translateY(-4px);
}
.service-card:hover::after, .service-card:focus-within::after { transform: scaleX(1); }
.service-icon {
  width: 49px; height: 49px; border-radius: 15px;
  color: var(--na-crimson); background: #fff0f3;
  box-shadow: inset 0 0 0 1px rgb(200 16 46 / 8%);
}
.service-number { color: #aaa4ac; font-size: 10px; font-weight: 800; }
.service-detail { color: var(--na-crimson-deep); font-size: 9px; letter-spacing: .13em; }
.service-card h3 { font-size: 17px; letter-spacing: -.035em; line-height: 1.35; }
.service-description { color: #706b74; font-size: 12px; line-height: 1.8; }
.service-link { color: #26232a; font-weight: 800; }
.service-link svg, .services-bottom a svg, .text-link-dark svg { color: var(--na-crimson); }
.service-link:hover, .services-bottom a:hover, .text-link-dark:hover { color: var(--na-crimson-deep); }
.services-bottom { padding-top: 27px; color: #6d6871; }

/* About section: richer dark surfaces and rounded photography, without fake claims or stats. */
.about-section {
  background: radial-gradient(ellipse at 0% 100%, rgb(200 16 46 / 15%) 0%, transparent 48%),
              linear-gradient(125deg, #242128 0%, #1b191f 60%, #28131b 100%);
}
.about-grid { gap: clamp(48px, 7vw, 90px); }
.about-visual { min-height: 510px; }
.about-visual::before { border-color: rgb(255 113 134 / 75%); }
.about-visual::after { background: linear-gradient(145deg, #e11d48, #9f1239); border-radius: 0 0 20px 0; }
.about-visual > img { height: 475px; border-radius: 19px; box-shadow: 0 23px 55px rgb(0 0 0 / 25%); }
.about-image-stamp { border-radius: 13px; box-shadow: 0 16px 42px rgb(0 0 0 / 25%); }
.stamp-icon { color: #fff; background: linear-gradient(135deg, #e11d48, #9f1239); }
.about-image-caption { color: rgb(255 255 255 / 95%); text-shadow: 0 1px 8px rgb(0 0 0 / 35%); }
.section-kicker-light { color: #ff9baa; }
.about-copy h2 span, .booking-aside h2 span { color: #ff8798; }
.about-lede { color: rgb(255 255 255 / 72%); line-height: 1.92; }
.about-points { gap: 20px; }
.point-check { border-color: rgb(255 135 152 / 55%); color: #ff8798; background: rgb(200 16 46 / 12%); }
.about-points small { color: rgb(255 255 255 / 62%); }
.about-copy .button { margin-top: 2px; }

.vehicle-section { background: #fff; }
.section-heading-centered { max-width: 740px; }
.vehicle-grid { gap: 18px; }
.vehicle-card {
  position: relative; padding: 28px; border: 1px solid rgb(42 31 38 / 9%); border-radius: 18px;
  background: linear-gradient(150deg, #fff 0%, #fbfafc 100%);
  box-shadow: 0 5px 18px rgb(28 20 26 / 3%);
}
.vehicle-card:hover, .vehicle-card:focus-within {
  border-color: rgb(200 16 46 / 25%); background: #fff;
  box-shadow: 0 18px 40px rgb(35 22 29 / 8%); transform: translateY(-4px);
}
.vehicle-icon { color: var(--na-crimson-deep); background: #fff0f3; border-radius: 15px; }
.vehicle-card h3 { font-family: "Manrope", sans-serif; font-size: 18px; font-weight: 750; }
.vehicle-card p { color: #6e6871; line-height: 1.85; }
.vehicle-card a { color: #28242b; }
.vehicle-card a svg { color: var(--na-crimson); }

.process-section {
  background: linear-gradient(135deg, #f0eef2 0%, #f8f7f9 55%, #f7eff1 100%);
}
.process-intro > p:not(.section-kicker) { color: #6b6570; line-height: 1.9; }
.process-steps { border-top-color: rgb(36 28 34 / 12%); }
.process-step { padding-block: 25px; border-bottom-color: rgb(36 28 34 / 12%); }
.process-number { color: var(--na-crimson); }
.process-step h3 { font-family: "Manrope", sans-serif; font-size: 15px; font-weight: 750; }
.process-step p { color: #716b75; line-height: 1.85; }
.process-arrow { color: var(--na-crimson); }

/* Appointment conversion area: dramatic background, legible form card and generous fields. */
.booking-section {
  position: relative; overflow: hidden;
  background: radial-gradient(ellipse at 4% 95%, rgb(200 16 46 / 23%) 0%, transparent 46%),
              radial-gradient(ellipse at 95% 0%, rgb(159 18 57 / 25%) 0%, transparent 43%),
              linear-gradient(130deg, #17151a 0%, #20171d 100%);
}
.booking-section::before {
  content: ""; position: absolute; inset: 0; pointer-events: none; opacity: .08;
  background-image: linear-gradient(rgb(255 255 255 / 12%) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 12%) 1px, transparent 1px);
  background-size: 68px 68px; mask-image: linear-gradient(120deg, black, transparent 70%);
}
.booking-layout { position: relative; z-index: 1; }
.booking-aside h2 span { color: #ff8798; }
.contact-icon { color: #ff8798; border-color: rgb(255 135 152 / 20%); background: rgb(255 255 255 / 3%); }
a.contact-detail:hover strong { color: #ff8798; }
.booking-note { border-radius: 12px; border-color: rgb(255 255 255 / 13%); background: rgb(255 255 255 / 4%); }
.booking-note svg { color: #ff8798; }
.booking-card {
  position: relative; border: 1px solid rgb(255 255 255 / 70%); border-radius: 22px;
  background: linear-gradient(150deg, #fff 0%, #fbfafc 100%);
  box-shadow: 0 28px 75px rgb(0 0 0 / 27%);
}
.booking-card-heading { padding-bottom: 21px; border-bottom: 1px solid rgb(32 24 30 / 8%); margin-bottom: 23px; }
.booking-card-heading h3 { font-family: "Manrope", sans-serif; font-weight: 800; letter-spacing: -.045em; }
.form-kicker { color: var(--na-crimson-deep); }
.booking-heading-icon { color: #fff; background: linear-gradient(135deg, #e11d48, #9f1239); border-radius: 14px; box-shadow: 0 7px 18px rgb(200 16 46 / 18%); }
.form-grid { gap: 18px 15px; }
.form-field label { color: #39333d; font-size: 11px; }
.form-field label > span:first-child { color: var(--na-crimson); }
.form-field input, .form-field textarea, .form-field select {
  min-height: 47px; padding: 12px 13px; border: 1px solid #ddd8df; border-radius: 10px;
  background: #fff; color: #2c2730; font-size: 12px;
  transition: border-color .2s ease, box-shadow .2s ease, background .2s ease;
}
.form-field input:focus, .form-field textarea:focus, .form-field select:focus {
  border-color: var(--na-crimson); box-shadow: 0 0 0 4px rgb(200 16 46 / 10%); outline: none;
}
.form-field input::placeholder, .form-field textarea::placeholder { color: #817984; opacity: 1; }
.form-field [aria-invalid="true"] { border-color: #b4233c; box-shadow: 0 0 0 3px rgb(180 35 60 / 9%); }
.form-privacy { color: #6d6671; line-height: 1.7; }

.closing-cta {
  padding-block: 42px;
  background: linear-gradient(115deg, #a60e2b 0%, #c8102e 50%, #8f1236 100%);
  color: #fff;
}
.closing-icon { color: #fff; border-color: rgb(255 255 255 / 30%); background: rgb(255 255 255 / 7%); border-radius: 16px; }
.closing-inner .section-kicker { color: #ffd6dd; }
.closing-inner h2 { color: #fff; font-weight: 800; }
.closing-inner .button-dark { background: #fff; color: #211a20; box-shadow: 0 8px 22px rgb(45 0 10 / 17%); }
.closing-inner .button-dark:hover { background: #fff0f3; }
.site-footer { background: linear-gradient(120deg, #17151a 0%, #21171e 100%); }
.footer-main { padding-block: 43px; }
.brand-footer .brand-copy b { color: #ff8798; }
.footer-main > p { color: rgb(255 255 255 / 59%); font-size: 11px; line-height: 1.8; }
.footer-links { gap: 18px; }
.footer-links a { font-size: 11px; }
.footer-links a:hover, .footer-bottom a:hover { color: #ff8798; }
.footer-bottom { color: rgb(255 255 255 / 48%); font-size: 10px; }
.floating-contact {
  min-height: 50px; border-radius: 999px; padding-inline: 18px;
  box-shadow: 0 14px 34px rgb(0 0 0 / 23%), 0 0 0 5px rgb(23 107 69 / 8%);
  transition: transform .22s ease, box-shadow .22s ease, background .22s ease;
}
.floating-contact:hover { transform: translateY(-3px); box-shadow: 0 18px 38px rgb(0 0 0 / 27%); }

/* Keep the cursor ambience visible but soft; never intercepts links or form controls. */
.cursor-ambient {
  z-index: 40; pointer-events: none; opacity: .62;
  background: radial-gradient(590px circle at var(--cursor-x, 50vw) var(--cursor-y, 35vh),
    color-mix(in srgb, var(--cursor-accent, #c8102e) 28%, transparent) 0%,
    color-mix(in srgb, var(--cursor-accent, #c8102e) 13%, transparent) 34%, transparent 72%);
  mix-blend-mode: soft-light;
  transition: opacity .25s ease;
}

@media (max-width: 980px) {
  .container { width: calc(100% - 44px); }
  .header-inner { gap: 18px; }
  .desktop-nav { gap: 15px; }
  .desktop-nav > a:not(.button) { font-size: 11px; }
  .hero-copy-wrap { width: min(750px, 90%); }
  .hero h1 { font-size: clamp(49px, 7.1vw, 74px); }
  .services-grid { gap: 14px; border: 0; }
  .service-card { min-height: 278px; padding: 23px; border: 1px solid rgb(42 31 38 / 9%); border-radius: 16px; }
  .about-visual { min-height: 450px; }
  .about-visual > img { height: 420px; }
  .booking-layout { gap: 34px; }
}
@media (max-width: 720px) {
  html { scroll-padding-top: 78px; }
  .container { width: calc(100% - 34px); }
  .header-inner { min-height: 70px; }
  .brand-mark { width: 39px; height: 39px; border-radius: 12px; }
  .brand-copy strong { font-size: 12px; }
  .brand-copy span { font-size: 8px; }
  .mobile-nav { background: rgb(255 255 255 / 98%); backdrop-filter: blur(16px); }
  .mobile-nav > a:not(.button) { padding-block: 14px; }
  .hero { min-height: clamp(650px, calc(100svh - 100px), 800px); }
  .hero-overlay {
    background:
      radial-gradient(ellipse at 75% 12%, rgb(200 16 46 / 18%) 0%, transparent 48%),
      linear-gradient(90deg, rgb(18 16 21 / 93%) 0%, rgb(22 17 23 / 76%) 75%, rgb(17 15 20 / 57%) 100%),
      linear-gradient(0deg, rgb(13 12 16 / 78%) 0%, transparent 45%);
  }
  .hero-container { padding-top: 66px; padding-bottom: 23px; }
  .hero-copy-wrap { width: 100%; min-height: 420px; }
  .hero h1 { font-size: clamp(42px, 10.6vw, 63px); line-height: 1.02; letter-spacing: -.065em; }
  .hero-description { font-size: 14px; line-height: 1.78; }
  .hero-actions { gap: 17px; }
  .hero-actions .button { width: 100%; max-width: 340px; }
  .hero-bottom-row { align-items: flex-end; gap: 12px; }
  .carousel-arrow, .carousel-pause { width: 34px; height: 34px; }
  .progress-segment { width: 18px; }
  .service-ribbon { padding-block: 18px; }
  .ribbon-inner { min-height: 0; }
  .ribbon-items { justify-content: flex-start; gap: 11px 16px; }
  .ribbon-items span { font-size: 9px; }
  .section { padding-block: 72px; }
  .section-heading { margin-bottom: 30px; }
  .section-heading h2, .about-copy h2, .process-intro h2, .booking-aside h2 { font-size: clamp(35px, 9vw, 48px); }
  .services-grid { grid-template-columns: minmax(0, 1fr); gap: 13px; }
  .service-card { min-height: 0; padding: 23px; }
  .service-description { margin-bottom: 21px; }
  .about-grid { gap: 40px; }
  .about-visual { min-height: 365px; padding: 0 19px 22px 0; }
  .about-visual > img { height: 345px; }
  .about-copy h2 { font-size: clamp(35px, 9.2vw, 42px); }
  .vehicle-grid { gap: 13px; margin-top: 34px; }
  .vehicle-card { padding: 23px; }
  .process-layout { gap: 30px; }
  .process-step { padding-block: 20px; }
  .booking-layout { gap: 31px; }
  .booking-card { padding: 23px 18px; border-radius: 18px; }
  .booking-card-heading h3 { font-size: 25px; }
  .form-grid { grid-template-columns: minmax(0, 1fr); gap: 15px; }
  .form-field-wide { grid-column: auto; }
  .form-field input, .form-field textarea, .form-field select { min-height: 48px; font-size: 16px; }
  .closing-inner { gap: 14px; }
  .closing-inner .button { width: 100%; margin: 6px 0 0; }
  .footer-main { gap: 19px; }
  .floating-contact { right: 13px; bottom: 13px; min-height: 47px; }
  .cursor-ambient { display: none; }
}
@media (max-width: 380px) {
  .container { width: calc(100% - 28px); }
  .utility-inner .utility-item { font-size: 8px; }
  .hero h1 { font-size: 40px; }
  .carousel-count { display: none; }
  .booking-card { padding-inline: 15px; }
}
@media (hover: none), (pointer: coarse) {
  .cursor-ambient { display: none; }
}
@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  *, *::before, *::after { animation-duration: .01ms !important; animation-iteration-count: 1 !important; transition-duration: .01ms !important; }
  .service-card:hover, .vehicle-card:hover, .button:hover, .floating-contact:hover { transform: none; }
  .cursor-ambient { display: none; }
}
'''
    css = css.rstrip() + polish + "\n"
    print("[design] Applied the modern crimson design layer")
else:
    print("[skip] Modern crimson design layer already exists; no duplicate styles added")

css_path.write_text(css)
html_path.write_text(html)
print("[done] Updated CSS design system and font metadata")
PY

cd "$PROJECT_DIR"
run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then log ok "$label passed"; else fail "$label failed. Your originals remain in $BACKUP_DIR"; fi
}
run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "ESLint/Oxlint" npm run lint
run_check "Production build" npm run build

log done "Modern crimson UI refinement is complete."
printf '\nProject: %s\nBackup:  %s\n' "$PROJECT_DIR" "$BACKUP_DIR"
printf '\nRefresh the existing browser tab if Vite is running. Otherwise run:\n  cd "%s"\n  npm run dev\n' "$PROJECT_DIR"
