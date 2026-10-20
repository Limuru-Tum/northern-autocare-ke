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
            initial={{ opacity: 0, scale: reducedMotion ? 1 : 1.012 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reducedMotion ? 0.01 : 1.12, ease: [0.22, 1, 0.36, 1] }}
            fetchPriority="high"
          />
        </AnimatePresence>
        <div className="hero-overlay" />
        <div className="hero-grid" />
      </div>

      <div className="container hero-container">
        <div className="hero-copy-wrap">
          <AnimatePresence mode="wait" initial={false}>
            <motion.div
              key={activeSlide.id}
              className="hero-copy"
              initial={{ opacity: 0, y: reducedMotion ? 0 : 7 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{
                opacity: 0,
                y: reducedMotion ? 0 : -4,
                transition: { duration: reducedMotion ? 0.01 : 0.2, ease: "easeIn" },
              }}
              transition={{ duration: reducedMotion ? 0.01 : 0.46, ease: [0.16, 1, 0.3, 1] }}
            >
              <div className="eyebrow eyebrow-light"><span className="eyebrow-dot" />{activeSlide.eyebrow}</div>
              <h1 aria-label={activeSlide.title.join(" ")}>{activeSlide.title[0]}<br /><span>{activeSlide.title[1]}</span></h1>
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
