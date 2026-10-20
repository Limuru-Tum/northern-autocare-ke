#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"

info() { printf '\033[0;36m[build]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[ok]\033[0m %s\n' "$*"; }
note() { printf '\033[0;33m[note]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
trap 'fail "Build stopped near line $LINENO. The error above identifies the failing step; your pre-build files are backed up."' ERR

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" && -f "$PROJECT_DIR/src/main.tsx" ]] || fail "Expected a Vite React project at: $PROJECT_DIR"
command -v node >/dev/null 2>&1 || fail "Node.js is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."

cd "$PROJECT_DIR"
info "Building the first Northern Autocare KE website experience in: $PROJECT_DIR"

# Check dependencies first; install only if one of the required packages is absent.
if ! node -e "for (const p of ['motion/react','lucide-react','react-hook-form','zod','@hookform/resolvers/zod','@testing-library/react','@testing-library/jest-dom','vitest']) require.resolve(p)" >/dev/null 2>&1; then
  info "Installing missing frontend or test dependencies..."
  npm install motion lucide-react react-hook-form zod @hookform/resolvers clsx tailwind-merge class-variance-authority tw-animate-css
  npm install -D tailwindcss @tailwindcss/vite vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom @types/node
else
  ok "Required frontend and test dependencies are already installed."
fi

mkdir -p src/components/layout src/components/home src/components/services src/components/booking src/components/ui src/config src/data src/test public/images

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/Desktop/northern-autocare-ke-backup-$STAMP"
mkdir -p "$BACKUP_DIR"
for f in src/App.tsx src/App.test.tsx src/index.css src/test/setup.ts index.html; do
  if [[ -f "$f" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp -p "$f" "$BACKUP_DIR/$f"
  fi
done
info "Existing app entry files backed up to: $BACKUP_DIR"

cat > src/config/business.ts <<'FILE_EOF'
export const business = {
  name: "Northern Autocare KE",
  shortName: "Northern Autocare",
  location: "Lodwar, Turkana County, Kenya",
  phoneDisplay: "+254 745 777702",
  phoneDial: "+254745777702",
  whatsappNumber: "254745777702",
} as const;
FILE_EOF

cat > src/data/services.ts <<'FILE_EOF'
import {
  CircleDot,
  Cog,
  Droplets,
  ScanSearch,
  Wrench,
  PackageCheck,
  type LucideIcon,
} from "lucide-react";

export type AutoService = {
  id: string;
  title: string;
  description: string;
  detail: string;
  icon: LucideIcon;
};

export const services: AutoService[] = [
  {
    id: "wheel-services",
    title: "Wheel balancing & alignment",
    description: "A steadier drive, more even tyre wear, and better control on the road.",
    detail: "Wheels & tyres",
    icon: CircleDot,
  },
  {
    id: "computer-diagnostics",
    title: "Computerized diagnostics",
    description: "Bring warning lights and unexpected faults into clearer focus with diagnostic checks.",
    detail: "Find the fault",
    icon: ScanSearch,
  },
  {
    id: "routine-servicing",
    title: "Routine servicing & oil changes",
    description: "Scheduled maintenance that helps your vehicle stay ready for the journeys ahead.",
    detail: "Preventive care",
    icon: Droplets,
  },
  {
    id: "engine-services",
    title: "Engine overhauls & assembly",
    description: "Engine repair, overhaul, and V6 or diesel engine assembly work.",
    detail: "Engine workshop",
    icon: Cog,
  },
  {
    id: "mechanical-repairs",
    title: "General mechanical repairs",
    description: "Repair support for saloon cars, 4x4 pickups, and commercial vans including Hiace matatus.",
    detail: "Cars, pickups & vans",
    icon: Wrench,
  },
  {
    id: "spare-parts",
    title: "Affordable spare parts",
    description: "Automotive spare-parts support to help keep vehicle maintenance within reach.",
    detail: "Parts support",
    icon: PackageCheck,
  },
];
FILE_EOF

cat > src/components/layout/SiteHeader.tsx <<'FILE_EOF'
import { useEffect, useState } from "react";
import { MapPin, Menu, Phone, Wrench, X } from "lucide-react";
import { business } from "@/config/business";

const links = [
  { label: "Services", href: "#services" },
  { label: "Our approach", href: "#about" },
  { label: "Vehicles", href: "#vehicles" },
  { label: "Contact", href: "#contact" },
];

export function SiteHeader() {
  const [menuOpen, setMenuOpen] = useState(false);

  const closeMenu = () => setMenuOpen(false);

  return (
    <>
      <div className="utility-bar">
        <div className="container utility-inner">
          <span className="utility-item"><MapPin aria-hidden="true" size={14} /> Lodwar, Turkana County</span>
          <a className="utility-item utility-phone" href={`tel:${business.phoneDial}`}>
            <Phone aria-hidden="true" size={14} /> Workshop enquiries <strong>{business.phoneDisplay}</strong>
          </a>
        </div>
      </div>
      <header className="site-header">
        <div className="container header-inner">
          <a className="brand" href="#top" aria-label="Northern Autocare KE home" onClick={closeMenu}>
            <span className="brand-mark"><Wrench aria-hidden="true" size={23} strokeWidth={2.2} /></span>
            <span className="brand-copy"><strong>NORTHERN</strong><span>AUTOCARE <b>KE</b></span></span>
          </a>

          <nav className={`desktop-nav${menuOpen ? " nav-open" : ""}`} aria-label="Main navigation">
            {links.map((link) => (
              <a key={link.href} href={link.href} onClick={closeMenu}>{link.label}</a>
            ))}
            <a className="button button-dark nav-book" href="#booking" onClick={closeMenu}>Book a service <span aria-hidden="true">↗</span></a>
          </nav>

          <button
            className="menu-toggle"
            type="button"
            aria-label={menuOpen ? "Close navigation menu" : "Open navigation menu"}
            aria-expanded={menuOpen}
            aria-controls="mobile-navigation"
            onClick={() => setMenuOpen((open) => !open)}
          >
            {menuOpen ? <X size={22} aria-hidden="true" /> : <Menu size={22} aria-hidden="true" />}
          </button>
        </div>
        <div id="mobile-navigation" className={`mobile-nav${menuOpen ? " mobile-nav-open" : ""}`} hidden={!menuOpen}>
          {links.map((link) => (
            <a key={link.href} href={link.href} onClick={closeMenu}>{link.label}</a>
          ))}
          <a className="button button-dark" href="#booking" onClick={closeMenu}>Book a service <span aria-hidden="true">↗</span></a>
        </div>
      </header>
    </>
  );
}
FILE_EOF

cat > src/components/home/HeroCarousel.tsx <<'FILE_EOF'
import { useEffect, useState } from "react";
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
];

export function HeroCarousel() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [paused, setPaused] = useState(false);
  const reducedMotion = useReducedMotion();
  const activeSlide = slides[activeIndex];

  useEffect(() => {
    if (paused || reducedMotion) return;
    const timer = window.setInterval(() => {
      setActiveIndex((current) => (current + 1) % slides.length);
    }, 7000);
    return () => window.clearInterval(timer);
  }, [paused, reducedMotion]);

  const previous = () => setActiveIndex((current) => (current - 1 + slides.length) % slides.length);
  const next = () => setActiveIndex((current) => (current + 1) % slides.length);

  return (
    <section className="hero" aria-label="Featured automotive services">
      <div className="hero-media" aria-hidden="true">
        <AnimatePresence initial={false}>
          <motion.img
            key={activeSlide.id}
            className="hero-image"
            src={activeSlide.image}
            alt=""
            initial={{ opacity: 0, scale: reducedMotion ? 1 : 1.045 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: reducedMotion ? 0.01 : 1.1, ease: [0.22, 1, 0.36, 1] }}
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
              initial={{ opacity: 0, y: reducedMotion ? 0 : 18 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: reducedMotion ? 0 : -10 }}
              transition={{ duration: reducedMotion ? 0.01 : 0.5, ease: "easeOut" }}
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
          <div className="carousel-controls" aria-label="Hero carousel controls">
            <span className="carousel-count"><strong>0{activeIndex + 1}</strong><span>/</span>0{slides.length}</span>
            <div className="carousel-progress" aria-label={`Slide ${activeIndex + 1} of ${slides.length}`}>
              {slides.map((slide, index) => (
                <button
                  type="button"
                  key={slide.id}
                  className={`progress-segment${index === activeIndex ? " progress-active" : ""}`}
                  aria-label={`Show slide ${index + 1}: ${slide.title.join(" ")}`}
                  aria-current={index === activeIndex ? "true" : undefined}
                  onClick={() => setActiveIndex(index)}
                ><span /></button>
              ))}
            </div>
            <button type="button" className="carousel-arrow" aria-label="Previous slide" onClick={previous}><ChevronLeft size={19} aria-hidden="true" /></button>
            <button type="button" className="carousel-arrow" aria-label="Next slide" onClick={next}><ChevronRight size={19} aria-hidden="true" /></button>
            {!reducedMotion && <button type="button" className="carousel-pause" aria-label={paused ? "Play automatic slides" : "Pause automatic slides"} onClick={() => setPaused((value) => !value)}>{paused ? <Play size={15} aria-hidden="true" /> : <Pause size={15} aria-hidden="true" />}</button>}
          </div>
        </div>
      </div>
      <div className="hero-index-watermark" aria-hidden="true">N<span>A</span> / KE</div>
    </section>
  );
}
FILE_EOF

cat > src/components/services/ServiceCard.tsx <<'FILE_EOF'
import { ArrowUpRight } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import type { AutoService } from "@/data/services";

type ServiceCardProps = {
  service: AutoService;
  index: number;
};

export function ServiceCard({ service, index }: ServiceCardProps) {
  const reducedMotion = useReducedMotion();
  const Icon = service.icon;

  return (
    <motion.article
      className="service-card"
      initial={reducedMotion ? false : { opacity: 0, y: 18 }}
      whileInView={reducedMotion ? undefined : { opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.15 }}
      transition={{ duration: 0.42, delay: index * 0.055, ease: "easeOut" }}
    >
      <div className="service-card-top"><span className="service-icon"><Icon aria-hidden="true" size={23} strokeWidth={1.7} /></span><span className="service-number">0{index + 1}</span></div>
      <p className="service-detail">{service.detail}</p>
      <h3>{service.title}</h3>
      <p className="service-description">{service.description}</p>
      <a className="service-link" href="#booking" onClick={() => window.dispatchEvent(new CustomEvent("northern-autocare:choose-service", { detail: service.title }))}>
        Book this service <ArrowUpRight aria-hidden="true" size={17} />
      </a>
    </motion.article>
  );
}
FILE_EOF

cat > src/components/ui/button.tsx <<'FILE_EOF'
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:opacity-90",
        dark: "bg-secondary text-white hover:opacity-90",
        amber: "bg-[var(--na-amber)] text-[#1b1d20] hover:opacity-90",
        outline: "border border-input bg-background hover:bg-accent",
        ghost: "hover:bg-accent hover:text-accent-foreground",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: { variant: "default", size: "default" },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, type = "button", ...props }, ref) => (
    <button ref={ref} type={type} className={cn(buttonVariants({ variant, size }), className)} {...props} />
  ),
);
Button.displayName = "Button";

export { Button, buttonVariants };
FILE_EOF

cat > src/components/booking/AppointmentForm.tsx <<'FILE_EOF'
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { ArrowRight, CheckCircle2, MessageCircle } from "lucide-react";
import { business } from "@/config/business";
import { services } from "@/data/services";
import { Button } from "@/components/ui/button";

const todayLocal = () => {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
};

const bookingSchema = z.object({
  fullName: z.string().trim().min(2, "Enter your name so the workshop knows who to contact."),
  phone: z.string().trim().regex(/^\+?[0-9][0-9\s()-]{7,18}$/, "Enter a valid phone number, including the country code if needed."),
  vehicleType: z.string().min(1, "Choose the type of vehicle."),
  vehicleDetails: z.string().trim().min(2, "Enter your vehicle make and model."),
  service: z.string().min(1, "Choose the service you need."),
  preferredDate: z.string().min(1, "Choose a preferred date.").refine((value) => value >= todayLocal(), "Choose today or a future date."),
  preferredTime: z.string().min(1, "Choose a preferred time."),
  notes: z.string().max(500, "Keep additional details under 500 characters."),
});

type BookingValues = z.infer<typeof bookingSchema>;

const initialValues: BookingValues = {
  fullName: "",
  phone: "",
  vehicleType: "",
  vehicleDetails: "",
  service: "",
  preferredDate: "",
  preferredTime: "",
  notes: "",
};

function FieldError({ id, message }: { id: string; message?: string }) {
  if (!message) return null;
  return <p className="field-error" id={id}>{message}</p>;
}

export function AppointmentForm() {
  const [whatsAppLink, setWhatsAppLink] = useState<string | null>(null);
  const { register, handleSubmit, formState: { errors, isSubmitting }, reset, setValue } = useForm<BookingValues>({
    resolver: zodResolver(bookingSchema),
    defaultValues: initialValues,
  });

  useEffect(() => {
    const handleServiceChoice = (event: Event) => {
      if (!(event instanceof CustomEvent) || typeof event.detail !== "string") return;
      if (!services.some((service) => service.title === event.detail)) return;
      setValue("service", event.detail, { shouldValidate: true, shouldDirty: true });
    };
    window.addEventListener("northern-autocare:choose-service", handleServiceChoice);
    return () => window.removeEventListener("northern-autocare:choose-service", handleServiceChoice);
  }, [setValue]);

  const onSubmit = (values: BookingValues) => {
    const message = [
      `Hello ${business.name}, I would like to request an appointment.`,
      "",
      `Name: ${values.fullName}`,
      `Phone: ${values.phone}`,
      `Vehicle: ${values.vehicleType} — ${values.vehicleDetails}`,
      `Service: ${values.service}`,
      `Preferred date: ${values.preferredDate}`,
      `Preferred time: ${values.preferredTime}`,
      `Additional details: ${values.notes.trim() || "None provided"}`,
      "",
      "I understand this is a request and the workshop will confirm availability.",
    ].join("\n");
    setWhatsAppLink(`https://wa.me/${business.whatsappNumber}?text=${encodeURIComponent(message)}`);
  };

  return (
    <div className="booking-card">
      <div className="booking-card-heading"><div><p className="form-kicker">APPOINTMENT REQUEST</p><h3>Tell us what your vehicle needs.</h3></div><span className="booking-heading-icon"><MessageCircle size={22} aria-hidden="true" /></span></div>
      <p className="booking-intro">Share a few details. We’ll prepare a message for the workshop so the team can follow up with you.</p>

      <form className="booking-form" onSubmit={handleSubmit(onSubmit)} noValidate>
        <div className="form-grid">
          <div className="form-field">
            <label htmlFor="fullName">Full name <span aria-hidden="true">*</span></label>
            <input id="fullName" autoComplete="name" placeholder="Your name" {...register("fullName")} aria-invalid={Boolean(errors.fullName)} aria-describedby={errors.fullName ? "fullName-error" : undefined} />
            <FieldError id="fullName-error" message={errors.fullName?.message} />
          </div>
          <div className="form-field">
            <label htmlFor="phone">Phone number <span aria-hidden="true">*</span></label>
            <input id="phone" type="tel" autoComplete="tel" placeholder="e.g. +254 7XX XXX XXX" {...register("phone")} aria-invalid={Boolean(errors.phone)} aria-describedby={errors.phone ? "phone-error" : undefined} />
            <FieldError id="phone-error" message={errors.phone?.message} />
          </div>
          <div className="form-field">
            <label htmlFor="vehicleType">Vehicle type <span aria-hidden="true">*</span></label>
            <select id="vehicleType" {...register("vehicleType")} aria-invalid={Boolean(errors.vehicleType)} aria-describedby={errors.vehicleType ? "vehicleType-error" : undefined}>
              <option value="">Select vehicle type</option>
              <option value="Saloon car">Saloon car</option>
              <option value="4x4 pickup">4x4 pickup</option>
              <option value="Commercial van / matatu">Commercial van / matatu</option>
              <option value="Other vehicle">Other</option>
            </select>
            <FieldError id="vehicleType-error" message={errors.vehicleType?.message} />
          </div>
          <div className="form-field">
            <label htmlFor="vehicleDetails">Vehicle make & model <span aria-hidden="true">*</span></label>
            <input id="vehicleDetails" placeholder="e.g. Toyota Hilux 2018" {...register("vehicleDetails")} aria-invalid={Boolean(errors.vehicleDetails)} aria-describedby={errors.vehicleDetails ? "vehicleDetails-error" : undefined} />
            <FieldError id="vehicleDetails-error" message={errors.vehicleDetails?.message} />
          </div>
          <div className="form-field form-field-wide">
            <label htmlFor="service">Service required <span aria-hidden="true">*</span></label>
            <select id="service" {...register("service")} aria-invalid={Boolean(errors.service)} aria-describedby={errors.service ? "service-error" : undefined}>
              <option value="">Choose a service</option>
              {services.map((service) => <option key={service.id} value={service.title}>{service.title}</option>)}
            </select>
            <FieldError id="service-error" message={errors.service?.message} />
          </div>
          <div className="form-field">
            <label htmlFor="preferredDate">Preferred date <span aria-hidden="true">*</span></label>
            <input id="preferredDate" type="date" min={todayLocal()} {...register("preferredDate")} aria-invalid={Boolean(errors.preferredDate)} aria-describedby={errors.preferredDate ? "preferredDate-error" : undefined} />
            <FieldError id="preferredDate-error" message={errors.preferredDate?.message} />
          </div>
          <div className="form-field">
            <label htmlFor="preferredTime">Preferred time <span aria-hidden="true">*</span></label>
            <select id="preferredTime" {...register("preferredTime")} aria-invalid={Boolean(errors.preferredTime)} aria-describedby={errors.preferredTime ? "preferredTime-error" : undefined}>
              <option value="">Choose a time</option>
              <option value="8:00 AM – 10:00 AM">8:00 AM – 10:00 AM</option>
              <option value="10:00 AM – 12:00 PM">10:00 AM – 12:00 PM</option>
              <option value="12:00 PM – 2:00 PM">12:00 PM – 2:00 PM</option>
              <option value="2:00 PM – 4:00 PM">2:00 PM – 4:00 PM</option>
              <option value="4:00 PM – 6:00 PM">4:00 PM – 6:00 PM</option>
              <option value="Flexible">Flexible — please advise</option>
            </select>
            <FieldError id="preferredTime-error" message={errors.preferredTime?.message} />
          </div>
          <div className="form-field form-field-wide">
            <label htmlFor="notes">Anything else we should know? <span className="label-optional">Optional</span></label>
            <textarea id="notes" rows={3} placeholder="Describe the issue, warning light, or any details that may help..." {...register("notes")} aria-invalid={Boolean(errors.notes)} aria-describedby={errors.notes ? "notes-error" : undefined} />
            <FieldError id="notes-error" message={errors.notes?.message} />
          </div>
        </div>

        <Button variant="amber" className="button button-amber button-large booking-submit" type="submit" disabled={isSubmitting}>
          Prepare WhatsApp request <ArrowRight aria-hidden="true" size={18} />
        </Button>
        <p className="form-privacy">Your details will be included in a message you can review before sending.</p>
      </form>

      {whatsAppLink && (
        <div className="booking-success" role="status" aria-live="polite">
          <CheckCircle2 aria-hidden="true" size={22} />
          <div><strong>Your request is ready to send.</strong><p>This is not yet a confirmed booking. Send the message to the workshop and wait for the team to confirm your preferred time.</p><a className="button button-whatsapp" href={whatsAppLink} target="_blank" rel="noreferrer">Send request on WhatsApp <ArrowRight aria-hidden="true" size={17} /></a><button className="edit-request" type="button" onClick={() => { setWhatsAppLink(null); reset(undefined, { keepValues: true }); }}>Edit request</button></div>
        </div>
      )}
    </div>
  );
}
FILE_EOF

cat > src/App.tsx <<'FILE_EOF'
import { useCallback, type PointerEvent } from "react";
import { ArrowRight, BadgeCheck, CarFront, Check, Clock3, MapPin, MessageCircle, ShieldCheck, Truck, Wrench } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SiteHeader } from "@/components/layout/SiteHeader";
import { HeroCarousel } from "@/components/home/HeroCarousel";
import { ServiceCard } from "@/components/services/ServiceCard";
import { AppointmentForm } from "@/components/booking/AppointmentForm";
import { business } from "@/config/business";
import { services } from "@/data/services";
import { Button } from "@/components/ui/button";

const vehicles = [
  { title: "Saloon cars", description: "Routine servicing, diagnostics, wheel services, and mechanical repairs.", icon: CarFront },
  { title: "4×4 pickups", description: "Practical repair and maintenance support for work and everyday travel.", icon: Truck },
  { title: "Commercial vans", description: "Support for working vehicles, including Toyota Hiace matatus.", icon: Wrench },
];

const steps = [
  { number: "01", title: "Tell us what’s happening", body: "Choose a service and describe your vehicle or the issue you have noticed." },
  { number: "02", title: "Request your preferred time", body: "Send your details to the workshop so the team can review your request." },
  { number: "03", title: "Get confirmation", body: "The workshop will reply to confirm availability before your visit." },
];

export default function App() {
  const reducedMotion = useReducedMotion();

  const handlePointerMove = useCallback((event: PointerEvent<HTMLDivElement>) => {
    if (event.pointerType !== "mouse" || reducedMotion || typeof window === "undefined") return;
    const x = Math.max(0, Math.min(1, event.clientX / window.innerWidth));
    const hue = Math.round(28 + x * 145);
    const root = document.documentElement;
    root.style.setProperty("--cursor-x", `${event.clientX}px`);
    root.style.setProperty("--cursor-y", `${event.clientY}px`);
    root.style.setProperty("--cursor-accent", `hsl(${hue} 76% 54%)`);
  }, [reducedMotion]);

  return (
    <div className="site-shell" onPointerMove={handlePointerMove}>
      <div className="cursor-ambient" aria-hidden="true" />
      <div id="top" />
      <SiteHeader />
      <main>
        <HeroCarousel />

        <section className="service-ribbon" aria-label="Our core service areas">
          <div className="container ribbon-inner">
            <span>Vehicle care, all in one place</span>
            <div className="ribbon-items"><span><Check size={15} aria-hidden="true" /> Diagnostics</span><span><Check size={15} aria-hidden="true" /> Wheel services</span><span><Check size={15} aria-hidden="true" /> Engine care</span><span><Check size={15} aria-hidden="true" /> Spare parts</span></div>
          </div>
        </section>

        <section className="section services-section" id="services">
          <div className="container">
            <div className="section-heading section-heading-split">
              <div><p className="section-kicker">WHAT WE DO</p><h2>Good care starts<br /><span>with the right work.</span></h2></div>
              <p className="section-lede">From small maintenance jobs to more involved mechanical work, find practical automotive services for the vehicle you depend on.</p>
            </div>
            <div className="services-grid">
              {services.map((service, index) => <ServiceCard key={service.id} service={service} index={index} />)}
            </div>
            <div className="services-bottom"><span>Not sure which service you need?</span><a href="#booking">Tell us what’s going on <ArrowRight aria-hidden="true" size={17} /></a></div>
          </div>
        </section>

        <section className="about-section" id="about">
          <div className="container about-grid">
            <motion.div className="about-visual" initial={reducedMotion ? false : { opacity: 0, x: -20 }} whileInView={reducedMotion ? undefined : { opacity: 1, x: 0 }} viewport={{ once: true, amount: 0.2 }} transition={{ duration: 0.6 }}>
              <img src="https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=1200&q=85" alt="Vehicle being worked on in an automotive service workshop" loading="lazy" />
              <div className="about-image-stamp"><span className="stamp-icon"><Wrench aria-hidden="true" size={21} /></span><span><strong>Practical expertise</strong><small>Care for the journey ahead</small></span></div>
              <div className="about-image-caption"><span>NA</span><span>LODWAR · KENYA</span></div>
            </motion.div>

            <div className="about-copy">
              <p className="section-kicker section-kicker-light">A WORKSHOP THAT GETS YOU MOVING</p>
              <h2>Every vehicle has a job to do.<br /><span>We help it do yours.</span></h2>
              <p className="about-lede">Northern Autocare KE supports drivers and vehicle operators in Lodwar with everyday servicing, diagnostic checks, wheel services, engine work, and spare-parts support.</p>
              <div className="about-points">
                <div><span className="point-check"><Check size={15} aria-hidden="true" /></span><span><strong>Clear service options</strong><small>Understand the kind of care your vehicle may need.</small></span></div>
                <div><span className="point-check"><Check size={15} aria-hidden="true" /></span><span><strong>Support across vehicle types</strong><small>From saloon cars to pickups and commercial vans.</small></span></div>
                <div><span className="point-check"><Check size={15} aria-hidden="true" /></span><span><strong>Convenient contact</strong><small>Send a service request before planning your visit.</small></span></div>
              </div>
              <a className="button button-amber" href="#booking">Talk to the workshop <ArrowRight aria-hidden="true" size={17} /></a>
            </div>
          </div>
        </section>

        <section className="section vehicle-section" id="vehicles">
          <div className="container">
            <div className="section-heading section-heading-centered"><p className="section-kicker">MADE FOR YOUR KIND OF JOURNEY</p><h2>Different vehicles.<br /><span>One place to start.</span></h2><p className="section-lede">Tell us what you drive and what it needs. We’ll help you take the next step.</p></div>
            <div className="vehicle-grid">
              {vehicles.map((vehicle, index) => {
                const Icon = vehicle.icon;
                return <motion.article key={vehicle.title} className="vehicle-card" initial={reducedMotion ? false : { opacity: 0, y: 16 }} whileInView={reducedMotion ? undefined : { opacity: 1, y: 0 }} viewport={{ once: true, amount: 0.25 }} transition={{ duration: 0.4, delay: index * 0.08 }}><div className="vehicle-icon"><Icon size={25} strokeWidth={1.7} aria-hidden="true" /></div><h3>{vehicle.title}</h3><p>{vehicle.description}</p><a href="#booking" aria-label={`Request service for ${vehicle.title.toLowerCase()}`}>Request service <ArrowRight size={16} aria-hidden="true" /></a></motion.article>;
              })}
            </div>
          </div>
        </section>

        <section className="process-section">
          <div className="container process-layout">
            <div className="process-intro"><p className="section-kicker">SIMPLE FROM THE START</p><h2>Getting started<br /><span>should be easy.</span></h2><p>Let us know what your vehicle needs. We’ll use your request to start the conversation and confirm a suitable time.</p><a className="text-link-dark" href="#booking">Start an appointment request <ArrowRight size={17} aria-hidden="true" /></a></div>
            <div className="process-steps">{steps.map((step) => <div className="process-step" key={step.number}><span className="process-number">{step.number}</span><div><h3>{step.title}</h3><p>{step.body}</p></div><ArrowRight className="process-arrow" aria-hidden="true" size={18} /></div>)}</div>
          </div>
        </section>

        <section className="booking-section" id="booking">
          <div className="container booking-layout">
            <div className="booking-aside">
              <p className="section-kicker section-kicker-light">LET’S GET YOU BACK OUT THERE</p>
              <h2>Start with a<br /><span>service request.</span></h2>
              <p>Tell us a little about your vehicle and your preferred visit. We’ll prepare a WhatsApp message for you to review and send to the workshop.</p>
              <div className="contact-details" id="contact">
                <a href={`tel:${business.phoneDial}`} className="contact-detail"><span className="contact-icon"><MessageCircle size={19} aria-hidden="true" /></span><span><small>Call or message</small><strong>{business.phoneDisplay}</strong></span></a>
                <div className="contact-detail"><span className="contact-icon"><MapPin size={19} aria-hidden="true" /></span><span><small>Find us in</small><strong>{business.location}</strong></span></div>
                <div className="contact-detail"><span className="contact-icon"><Clock3 size={19} aria-hidden="true" /></span><span><small>Visit planning</small><strong>Contact us to confirm workshop availability</strong></span></div>
              </div>
              <div className="booking-note"><ShieldCheck size={19} aria-hidden="true" /><p>Your preferred time is a request, not a confirmed booking. The workshop will reply to confirm availability.</p></div>
            </div>
            <AppointmentForm />
          </div>
        </section>

        <section className="closing-cta"><div className="container closing-inner"><span className="closing-icon"><BadgeCheck size={24} aria-hidden="true" /></span><div><p className="section-kicker">NORTHERN AUTOCARE KE · LODWAR</p><h2>Keep your next journey in motion.</h2></div><a className="button button-dark" href="#booking">Request a service <ArrowRight aria-hidden="true" size={17} /></a></div></section>
      </main>

      <footer className="site-footer">
        <div className="container footer-main"><a className="brand brand-footer" href="#top" aria-label="Northern Autocare KE back to top"><span className="brand-mark"><Wrench aria-hidden="true" size={22} /></span><span className="brand-copy"><strong>NORTHERN</strong><span>AUTOCARE <b>KE</b></span></span></a><p>Automotive servicing, repairs, diagnostics, and spare-parts support in Lodwar.</p><div className="footer-links"><a href="#services">Services</a><a href="#about">Our approach</a><a href="#booking">Appointments</a><a href={`tel:${business.phoneDial}`}>Call workshop</a></div></div>
        <div className="container footer-bottom"><span>© {new Date().getFullYear()} Northern Autocare KE</span><span>Built for the road ahead.</span><a href="#top">Back to top ↑</a></div>
      </footer>

      <a className="floating-contact" href={`https://wa.me/${business.whatsappNumber}`} target="_blank" rel="noreferrer" aria-label="Chat with Northern Autocare KE on WhatsApp"><MessageCircle size={21} aria-hidden="true" /><span>Chat with us</span></a>
    </div>
  );
}
FILE_EOF

cat > src/index.css <<'FILE_EOF'
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  color-scheme: light;
  font-family: "DM Sans", "Segoe UI", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  font-optical-sizing: auto;
  font-weight: 400;
  --background: #f5f4f0;
  --foreground: #1b1d20;
  --na-ink: #1b1d20;
  --na-graphite: #202328;
  --na-graphite-deep: #151719;
  --na-ivory: #f5f4f0;
  --na-paper: #ffffff;
  --na-amber: #f0a52b;
  --na-amber-deep: #b86b0e;
  --na-muted: #767a80;
  --na-line: rgb(27 29 32 / 12%);
  --cursor-x: 50vw;
  --cursor-y: 35vh;
  --cursor-accent: #f0a52b;
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--na-amber);
  --color-secondary: var(--na-graphite);
  --font-sans: "DM Sans", "Segoe UI", ui-sans-serif, system-ui, sans-serif;
}

* { box-sizing: border-box; }
html { min-width: 320px; scroll-behavior: smooth; scroll-padding-top: 86px; text-size-adjust: 100%; }
body { min-width: 320px; min-height: 100vh; margin: 0; background: var(--na-ivory); color: var(--na-ink); }
button, input, textarea, select { font: inherit; }
button, a { -webkit-tap-highlight-color: transparent; }
button { cursor: pointer; }
a { color: inherit; text-decoration: none; }
img { display: block; max-width: 100%; }
::selection { color: var(--na-ink); background: rgb(240 165 43 / 35%); }
:focus-visible { outline: 3px solid var(--na-amber); outline-offset: 3px; }

.site-shell { position: relative; isolation: isolate; overflow: clip; }
.cursor-ambient { position: fixed; inset: 0; z-index: 4; pointer-events: none; opacity: .22; background: radial-gradient(420px circle at var(--cursor-x) var(--cursor-y), color-mix(in srgb, var(--cursor-accent) 25%, transparent), transparent 68%); transition: opacity .3s ease, background-color .5s ease; mix-blend-mode: multiply; }
.site-shell > *:not(.cursor-ambient):not(.site-header) { position: relative; z-index: 2; }
.container { width: min(1200px, calc(100% - 56px)); margin-inline: auto; }
.utility-bar { background: var(--na-graphite-deep); color: rgb(255 255 255 / 73%); font-size: 11px; letter-spacing: .035em; }
.utility-inner { min-height: 36px; display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.utility-item { display: inline-flex; align-items: center; gap: 8px; }
.utility-item svg { color: var(--na-amber); }
.utility-phone { transition: color .2s ease; }
.utility-phone:hover { color: white; }
.utility-phone strong { color: white; font-weight: 600; }
.site-header { position: sticky; top: 0; z-index: 50 !important; background: rgb(248 247 243 / 94%); border-bottom: 1px solid rgb(27 29 32 / 8%); backdrop-filter: blur(18px); }
.header-inner { display: flex; align-items: center; justify-content: space-between; min-height: 78px; gap: 30px; }
.brand { display: inline-flex; align-items: center; gap: 11px; flex-shrink: 0; }
.brand-mark { display: grid; place-items: center; width: 43px; height: 43px; color: var(--na-amber); background: var(--na-graphite); border-radius: 13px; box-shadow: inset 0 0 0 1px rgb(255 255 255 / 8%); }
.brand-copy { display: grid; line-height: 1.04; letter-spacing: .09em; }
.brand-copy strong { font-size: 15px; font-weight: 850; letter-spacing: .15em; }
.brand-copy span { margin-top: 5px; font-size: 10px; font-weight: 650; letter-spacing: .25em; }
.brand-copy b { color: var(--na-amber-deep); font-weight: 850; }
.desktop-nav { display: flex; align-items: center; gap: clamp(18px, 3vw, 35px); }
.desktop-nav > a:not(.button) { font-size: 12px; color: #50535a; font-weight: 650; transition: color .2s ease; }
.desktop-nav > a:not(.button):hover { color: var(--na-amber-deep); }
.button { min-height: 46px; display: inline-flex; align-items: center; justify-content: center; gap: 11px; padding: 0 20px; border: 1px solid transparent; border-radius: 8px; font-size: 12px; font-weight: 750; letter-spacing: .005em; transition: transform .2s ease, background .2s ease, color .2s ease, border-color .2s ease, box-shadow .2s ease; }
.button:hover { transform: translateY(-2px); }
.button:active { transform: translateY(0); }
.button-dark { background: var(--na-graphite); color: #fff; box-shadow: 0 7px 20px rgb(17 18 20 / 10%); }
.button-dark:hover { background: #30343a; box-shadow: 0 10px 24px rgb(17 18 20 / 17%); }
.button-amber { background: var(--na-amber); color: #191b1e; box-shadow: 0 8px 24px rgb(240 165 43 / 18%); }
.button-amber:hover { background: #ffb63d; box-shadow: 0 11px 26px rgb(240 165 43 / 27%); }
.button-large { min-height: 54px; padding-inline: 22px; }
.nav-book { min-height: 42px; padding-inline: 17px; }
.menu-toggle, .mobile-nav { display: none; }

.hero { position: relative; min-height: min(730px, calc(100svh - 114px)); min-height: clamp(600px, calc(100svh - 114px), 760px); overflow: hidden; background: #17191c; color: white; }
.hero-media, .hero-overlay, .hero-grid { position: absolute; inset: 0; }
.hero-media { overflow: hidden; }
.hero-image { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; object-position: center 48%; filter: saturate(.78); }
.hero-overlay { background: linear-gradient(90deg, rgb(17 19 21 / 93%) 0%, rgb(17 19 21 / 82%) 36%, rgb(17 19 21 / 48%) 67%, rgb(17 19 21 / 26%) 100%), linear-gradient(0deg, rgb(12 13 15 / 66%) 0%, transparent 34%); }
.hero-grid { opacity: .22; background-image: linear-gradient(rgb(255 255 255 / 5%) 1px, transparent 1px), linear-gradient(90deg, rgb(255 255 255 / 5%) 1px, transparent 1px); background-size: 82px 82px; mask-image: linear-gradient(90deg, black, transparent 90%); }
.hero-container { z-index: 3; display: flex; min-height: inherit; flex-direction: column; justify-content: space-between; padding-top: clamp(70px, 9vh, 108px); padding-bottom: 32px; }
.hero-copy-wrap { width: min(760px, 78%); min-height: 405px; }
.hero-copy { max-width: 710px; }
.eyebrow, .section-kicker { display: flex; align-items: center; gap: 10px; color: var(--na-amber-deep); font-size: 10px; font-weight: 800; letter-spacing: .2em; line-height: 1.5; }
.eyebrow-light { color: #f4c16b; }
.eyebrow-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--na-amber); box-shadow: 0 0 0 5px rgb(240 165 43 / 13%); }
.hero h1 { max-width: 800px; margin: 27px 0 0; font-size: clamp(47px, 6.2vw, 82px); font-weight: 650; line-height: .99; letter-spacing: -.065em; text-wrap: balance; }
.hero h1 span { color: var(--na-amber); }
.hero-description { max-width: 510px; margin: 25px 0 0; color: rgb(255 255 255 / 76%); font-size: clamp(14px, 1.45vw, 16px); line-height: 1.85; }
.hero-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 25px; margin-top: 32px; }
.hero-text-link { display: inline-flex; align-items: center; gap: 8px; color: white; font-size: 12px; font-weight: 650; transition: color .2s ease; }
.hero-text-link svg { color: var(--na-amber); transition: transform .2s ease; }
.hero-text-link:hover { color: var(--na-amber); }
.hero-text-link:hover svg { transform: translateY(3px); }
.hero-feature { display: inline-flex; align-items: center; gap: 10px; margin-top: 34px; color: rgb(255 255 255 / 78%); font-size: 11px; letter-spacing: .03em; }
.hero-feature-icon { display: grid; place-items: center; width: 31px; height: 31px; border: 1px solid rgb(255 255 255 / 20%); border-radius: 50%; color: var(--na-amber); }
.hero-bottom-row { display: flex; align-items: center; justify-content: space-between; gap: 24px; margin-top: 20px; }
.hero-location { display: inline-flex; align-items: center; gap: 12px; color: rgb(255 255 255 / 60%); font-size: 10px; letter-spacing: .06em; }
.location-line { width: 32px; height: 1px; background: var(--na-amber); }
.carousel-controls { display: flex; align-items: center; gap: 9px; }
.carousel-count { display: flex; align-items: center; gap: 6px; margin-right: 8px; color: rgb(255 255 255 / 55%); font-size: 10px; }
.carousel-count strong { color: white; font-size: 14px; }
.carousel-count span { color: var(--na-amber); }
.carousel-progress { display: flex; gap: 5px; margin-right: 14px; }
.progress-segment { width: 24px; height: 20px; display: flex; align-items: center; padding: 0; border: 0; background: transparent; }
.progress-segment span { width: 100%; height: 2px; background: rgb(255 255 255 / 30%); transition: background .25s ease, height .25s ease; }
.progress-segment:hover span { background: rgb(255 255 255 / 70%); }
.progress-segment.progress-active span { height: 3px; background: var(--na-amber); }
.carousel-arrow, .carousel-pause { display: grid; place-items: center; width: 37px; height: 37px; border: 1px solid rgb(255 255 255 / 28%); border-radius: 50%; background: rgb(255 255 255 / 5%); color: white; transition: background .2s ease, color .2s ease, border-color .2s ease; }
.carousel-arrow:hover, .carousel-pause:hover { color: var(--na-ink); background: var(--na-amber); border-color: var(--na-amber); }
.carousel-pause { width: 31px; height: 31px; border: 0; margin-left: 2px; }
.hero-index-watermark { position: absolute; top: 15%; right: 5.5%; z-index: 2; color: rgb(255 255 255 / 17%); font-size: 14px; font-weight: 800; letter-spacing: .18em; writing-mode: vertical-rl; }
.hero-index-watermark span { color: rgb(240 165 43 / 80%); }

.service-ribbon { background: var(--na-amber); }
.ribbon-inner { min-height: 75px; display: flex; align-items: center; justify-content: space-between; gap: 25px; }
.ribbon-inner > span { font-size: 12px; font-weight: 800; letter-spacing: .02em; }
.ribbon-items { display: flex; align-items: center; justify-content: flex-end; flex-wrap: wrap; gap: clamp(14px, 2.5vw, 30px); }
.ribbon-items span { display: inline-flex; align-items: center; gap: 7px; font-size: 10px; font-weight: 700; color: #29251d; }
.ribbon-items svg { stroke-width: 2.5; }
.section { padding-block: clamp(78px, 9vw, 122px); }
.services-section { background: var(--na-ivory); }
.section-heading { margin-bottom: 45px; }
.section-heading-split { display: flex; align-items: flex-end; justify-content: space-between; gap: 42px; }
.section-heading h2, .about-copy h2, .process-intro h2, .booking-aside h2 { margin: 17px 0 0; font-size: clamp(36px, 4.4vw, 56px); line-height: 1.07; letter-spacing: -.055em; font-weight: 650; text-wrap: balance; }
.section-heading h2 span { color: #7d8084; }
.section-lede { max-width: 390px; margin: 0 0 4px; color: #686c72; font-size: 14px; line-height: 1.8; }
.services-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); border-top: 1px solid var(--na-line); border-left: 1px solid var(--na-line); }
.service-card { display: flex; min-height: 295px; flex-direction: column; align-items: flex-start; padding: 26px 27px 24px; border-right: 1px solid var(--na-line); border-bottom: 1px solid var(--na-line); background: rgb(255 255 255 / 38%); transition: background .28s ease, transform .28s ease, box-shadow .28s ease; }
.service-card:hover { position: relative; z-index: 1; background: #fff; box-shadow: 0 18px 40px rgb(23 25 28 / 7%); transform: translateY(-4px); }
.service-card-top { width: 100%; display: flex; align-items: flex-start; justify-content: space-between; }
.service-icon { display: grid; place-items: center; width: 48px; height: 48px; border-radius: 14px; background: var(--na-graphite); color: var(--na-amber); }
.service-number { color: #a0a2a5; font-size: 10px; letter-spacing: .08em; }
.service-detail { margin: 23px 0 8px; color: var(--na-amber-deep); font-size: 9px; letter-spacing: .14em; font-weight: 800; text-transform: uppercase; }
.service-card h3 { max-width: 290px; margin: 0; font-size: 18px; line-height: 1.28; letter-spacing: -.025em; font-weight: 750; }
.service-description { margin: 10px 0 22px; color: #777b80; font-size: 12px; line-height: 1.75; }
.service-link { display: inline-flex; align-items: center; gap: 7px; margin-top: auto; color: #26292d; font-size: 11px; font-weight: 800; }
.service-link svg { color: var(--na-amber-deep); transition: transform .2s ease; }
.service-link:hover svg { transform: translate(3px, -3px); }
.services-bottom { display: flex; align-items: center; justify-content: space-between; gap: 20px; padding-top: 25px; color: #6e7176; font-size: 12px; }
.services-bottom a, .text-link-dark { display: inline-flex; align-items: center; gap: 9px; color: #1c1e21; font-weight: 800; transition: color .2s ease; }
.services-bottom a svg, .text-link-dark svg { color: var(--na-amber-deep); transition: transform .2s ease; }
.services-bottom a:hover, .text-link-dark:hover { color: var(--na-amber-deep); }
.services-bottom a:hover svg, .text-link-dark:hover svg { transform: translateX(3px); }

.about-section { padding-block: clamp(78px, 9vw, 120px); background: var(--na-graphite); color: white; }
.about-grid { display: grid; grid-template-columns: minmax(0, .95fr) minmax(0, 1fr); align-items: center; gap: clamp(48px, 8vw, 100px); }
.about-visual { position: relative; min-height: 530px; padding: 0 35px 35px 0; }
.about-visual::before { position: absolute; content: ""; top: -17px; left: -17px; width: 45%; height: 43%; border-top: 1px solid rgb(240 165 43 / 60%); border-left: 1px solid rgb(240 165 43 / 60%); }
.about-visual::after { position: absolute; content: ""; right: 0; bottom: 0; width: 48%; height: 42%; background: var(--na-amber); z-index: 0; }
.about-visual > img { position: relative; z-index: 1; width: 100%; height: 495px; object-fit: cover; object-position: center; filter: saturate(.78); }
.about-image-stamp { position: absolute; z-index: 3; left: -21px; bottom: 67px; display: flex; align-items: center; gap: 12px; padding: 15px 18px; color: var(--na-ink); background: #fff; box-shadow: 0 12px 40px rgb(0 0 0 / 17%); }
.stamp-icon { display: grid; place-items: center; width: 37px; height: 37px; border-radius: 9px; background: var(--na-amber); }
.about-image-stamp strong, .about-image-stamp small { display: block; }
.about-image-stamp strong { font-size: 11px; }
.about-image-stamp small { margin-top: 4px; color: #74777b; font-size: 9px; }
.about-image-caption { position: absolute; right: 22px; bottom: 13px; z-index: 2; display: flex; align-items: center; gap: 12px; color: #211f1b; font-size: 9px; letter-spacing: .17em; font-weight: 850; }
.about-image-caption span:first-child { font-size: 20px; letter-spacing: -.06em; }
.section-kicker-light { color: #f4c16b; }
.about-copy h2 { margin-top: 20px; font-size: clamp(35px, 4vw, 51px); }
.about-copy h2 span, .process-intro h2 span, .booking-aside h2 span { color: var(--na-amber); }
.about-lede { margin: 23px 0 0; color: rgb(255 255 255 / 66%); font-size: 13px; line-height: 1.9; }
.about-points { display: grid; gap: 19px; margin: 27px 0 32px; }
.about-points > div { display: flex; align-items: flex-start; gap: 12px; }
.point-check { display: grid; place-items: center; flex: 0 0 23px; width: 23px; height: 23px; border: 1px solid rgb(240 165 43 / 53%); border-radius: 50%; color: var(--na-amber); }
.about-points strong, .about-points small { display: block; }
.about-points strong { color: white; font-size: 12px; }
.about-points small { margin-top: 5px; color: rgb(255 255 255 / 53%); font-size: 11px; line-height: 1.6; }
.about-copy .button { min-height: 49px; }

.vehicle-section { background: #fff; }
.section-heading-centered { max-width: 690px; margin-inline: auto; text-align: center; }
.section-heading-centered .section-kicker { justify-content: center; }
.section-heading-centered .section-lede { max-width: 480px; margin: 17px auto 0; }
.vehicle-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; margin-top: 52px; }
.vehicle-card { padding: 29px; border: 1px solid rgb(27 29 32 / 10%); background: #faf9f6; transition: border-color .25s ease, transform .25s ease, box-shadow .25s ease; }
.vehicle-card:hover { border-color: rgb(184 107 14 / 35%); transform: translateY(-4px); box-shadow: 0 17px 35px rgb(24 25 26 / 6%); }
.vehicle-icon { display: grid; place-items: center; width: 48px; height: 48px; background: #f1dfc1; color: #5d3c15; border-radius: 14px; }
.vehicle-card h3 { margin: 25px 0 10px; font-size: 19px; letter-spacing: -.03em; }
.vehicle-card p { min-height: 63px; margin: 0; color: #70747a; font-size: 12px; line-height: 1.8; }
.vehicle-card a { display: inline-flex; align-items: center; gap: 8px; margin-top: 20px; color: #2a2c30; font-size: 11px; font-weight: 800; }
.vehicle-card a svg { color: var(--na-amber-deep); transition: transform .2s ease; }
.vehicle-card a:hover svg { transform: translateX(4px); }

.process-section { padding-block: clamp(72px, 8vw, 100px); background: #eceae4; }
.process-layout { display: grid; grid-template-columns: .8fr 1.2fr; align-items: start; gap: clamp(45px, 8vw, 100px); }
.process-intro h2 { margin-bottom: 20px; }
.process-intro > p:not(.section-kicker) { max-width: 340px; color: #6c7075; font-size: 13px; line-height: 1.85; }
.text-link-dark { margin-top: 18px; font-size: 12px; }
.process-steps { border-top: 1px solid rgb(27 29 32 / 15%); }
.process-step { display: grid; grid-template-columns: 40px 1fr 20px; align-items: start; gap: 18px; padding: 24px 0; border-bottom: 1px solid rgb(27 29 32 / 15%); }
.process-number { color: var(--na-amber-deep); font-size: 11px; font-weight: 850; letter-spacing: .09em; }
.process-step h3 { margin: 0; font-size: 15px; letter-spacing: -.015em; }
.process-step p { max-width: 410px; margin: 8px 0 0; color: #74777b; font-size: 12px; line-height: 1.75; }
.process-arrow { color: #a86c1d; }

.booking-section { padding-block: clamp(70px, 8vw, 105px); background: var(--na-graphite-deep); color: white; }
.booking-layout { display: grid; grid-template-columns: minmax(250px, .72fr) minmax(0, 1.28fr); align-items: start; gap: clamp(36px, 6.5vw, 82px); }
.booking-aside { padding-top: 18px; }
.booking-aside h2 { margin-top: 18px; font-size: clamp(38px, 4.3vw, 56px); }
.booking-aside > p:not(.section-kicker) { max-width: 370px; margin: 22px 0 0; color: rgb(255 255 255 / 62%); font-size: 13px; line-height: 1.9; }
.contact-details { display: grid; gap: 18px; margin-top: 36px; }
.contact-detail { display: flex; align-items: center; gap: 13px; min-width: 0; }
.contact-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border: 1px solid rgb(255 255 255 / 13%); border-radius: 13px; color: var(--na-amber); }
.contact-detail small, .contact-detail strong { display: block; }
.contact-detail small { color: rgb(255 255 255 / 48%); font-size: 10px; }
.contact-detail strong { margin-top: 5px; color: white; font-size: 12px; font-weight: 650; line-height: 1.5; }
a.contact-detail:hover strong { color: var(--na-amber); }
.booking-note { display: flex; align-items: flex-start; gap: 10px; margin-top: 32px; padding: 14px; border: 1px solid rgb(255 255 255 / 10%); border-radius: 8px; background: rgb(255 255 255 / 3%); }
.booking-note svg { flex: 0 0 auto; color: var(--na-amber); }
.booking-note p { margin: 0; color: rgb(255 255 255 / 62%); font-size: 10px; line-height: 1.75; }
.booking-card { padding: clamp(24px, 3.7vw, 42px); border-radius: 14px; background: #fbfaf7; color: var(--na-ink); box-shadow: 0 30px 75px rgb(0 0 0 / 19%); }
.booking-card-heading { display: flex; align-items: flex-start; justify-content: space-between; gap: 20px; }
.form-kicker { margin: 0; color: var(--na-amber-deep); font-size: 9px; letter-spacing: .18em; font-weight: 850; }
.booking-card-heading h3 { max-width: 430px; margin: 10px 0 0; font-size: clamp(24px, 2.7vw, 32px); line-height: 1.1; letter-spacing: -.045em; }
.booking-heading-icon { display: grid; place-items: center; flex: 0 0 43px; width: 43px; height: 43px; border-radius: 12px; background: var(--na-graphite); color: var(--na-amber); }
.booking-intro { margin: 14px 0 25px; color: #6c7075; font-size: 12px; line-height: 1.75; }
.form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 17px 14px; }
.form-field { min-width: 0; }
.form-field-wide { grid-column: 1 / -1; }
.form-field label { display: flex; align-items: center; gap: 5px; margin-bottom: 7px; color: #36393e; font-size: 11px; font-weight: 750; }
.form-field label > span:first-child { color: var(--na-amber-deep); }
.form-field label .label-optional { margin-left: auto; color: #8b8e92; font-size: 9px; font-weight: 550; }
.form-field input, .form-field textarea, .form-field select { display: block; width: 100%; min-height: 44px; padding: 11px 12px; border: 1px solid #ddddd8; border-radius: 7px; outline: none; background: #fff; color: #272a2e; font-size: 12px; transition: border-color .2s ease, box-shadow .2s ease, background .2s ease; }
.form-field textarea { min-height: 86px; resize: vertical; line-height: 1.6; }
.form-field input::placeholder, .form-field textarea::placeholder { color: #a1a2a2; }
.form-field input:focus, .form-field textarea:focus, .form-field select:focus { border-color: var(--na-amber-deep); box-shadow: 0 0 0 3px rgb(240 165 43 / 17%); }
.form-field [aria-invalid="true"] { border-color: #b9382e; }
.field-error { margin: 5px 0 0; color: #ad2b25; font-size: 10px; line-height: 1.5; }
.booking-submit { width: 100%; margin-top: 23px; }
.form-privacy { margin: 10px 0 0; color: #888b8e; font-size: 9px; line-height: 1.6; text-align: center; }
.booking-success { display: flex; align-items: flex-start; gap: 12px; margin-top: 20px; padding: 15px; border: 1px solid #bdd9c8; border-radius: 9px; background: #eef8f1; color: #1c5836; }
.booking-success > svg { flex: 0 0 auto; margin-top: 1px; }
.booking-success strong { display: block; font-size: 12px; }
.booking-success p { max-width: 470px; margin: 6px 0 12px; color: #4f6a58; font-size: 11px; line-height: 1.7; }
.button-whatsapp { min-height: 41px; padding-inline: 13px; background: #176b45; color: white; font-size: 11px; }
.button-whatsapp:hover { background: #125a39; }
.edit-request { display: inline-flex; margin-left: 12px; padding: 10px 4px; border: 0; background: transparent; color: #335d43; font-size: 11px; font-weight: 750; text-decoration: underline; text-underline-offset: 3px; }

.closing-cta { padding-block: 40px; background: var(--na-amber); }
.closing-inner { display: flex; align-items: center; gap: 20px; }
.closing-icon { display: grid; place-items: center; flex: 0 0 52px; width: 52px; height: 52px; border: 1px solid rgb(25 27 29 / 20%); border-radius: 15px; }
.closing-inner .section-kicker { margin: 0; color: #4d3514; font-size: 9px; }
.closing-inner h2 { margin: 6px 0 0; font-size: clamp(21px, 2.4vw, 29px); font-weight: 750; letter-spacing: -.04em; }
.closing-inner .button { margin-left: auto; flex-shrink: 0; }
.site-footer { background: #151719; color: white; }
.footer-main { display: grid; grid-template-columns: auto minmax(150px, 1fr) auto; align-items: center; gap: 35px; padding-block: 39px; }
.brand-footer .brand-mark { border: 1px solid rgb(255 255 255 / 10%); }
.brand-footer .brand-copy b { color: var(--na-amber); }
.footer-main > p { max-width: 260px; margin: 0; color: rgb(255 255 255 / 48%); font-size: 10px; line-height: 1.7; }
.footer-links { display: flex; flex-wrap: wrap; gap: 17px; }
.footer-links a { color: rgb(255 255 255 / 65%); font-size: 10px; transition: color .2s ease; }
.footer-links a:hover { color: var(--na-amber); }
.footer-bottom { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding-block: 17px; border-top: 1px solid rgb(255 255 255 / 10%); color: rgb(255 255 255 / 39%); font-size: 9px; letter-spacing: .04em; }
.footer-bottom a { color: rgb(255 255 255 / 63%); }
.footer-bottom a:hover { color: var(--na-amber); }
.floating-contact { position: fixed; right: 22px; bottom: 22px; z-index: 60; display: inline-flex; align-items: center; gap: 9px; min-height: 48px; padding: 0 17px; border: 1px solid rgb(255 255 255 / 15%); border-radius: 999px; background: #176b45; color: white; box-shadow: 0 12px 32px rgb(0 0 0 / 22%); font-size: 11px; font-weight: 800; transition: transform .2s ease, background .2s ease; }
.floating-contact:hover { transform: translateY(-3px); background: #125a39; }

@media (max-width: 980px) {
  .container { width: min(100% - 42px, 800px); }
  .desktop-nav { gap: 18px; }
  .desktop-nav > a:not(.button) { font-size: 11px; }
  .hero-copy-wrap { width: min(730px, 90%); }
  .hero h1 { font-size: clamp(48px, 7.2vw, 72px); }
  .section-heading-split { align-items: flex-start; }
  .services-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .about-grid { gap: 48px; }
  .about-visual { min-height: 440px; }
  .about-visual > img { height: 420px; }
  .booking-layout { grid-template-columns: minmax(220px, .7fr) minmax(0, 1.3fr); gap: 32px; }
  .footer-main { grid-template-columns: auto 1fr; }
  .footer-main > p { justify-self: end; }
  .footer-links { grid-column: 1 / -1; }
}

@media (max-width: 720px) {
  html { scroll-padding-top: 72px; }
  .container { width: calc(100% - 36px); }
  .utility-inner { min-height: 34px; }
  .utility-inner .utility-item { font-size: 9px; }
  .utility-phone { gap: 6px; }
  .utility-phone strong { display: none; }
  .header-inner { min-height: 70px; }
  .brand-mark { width: 39px; height: 39px; border-radius: 11px; }
  .brand-copy strong { font-size: 13px; }
  .brand-copy span { font-size: 9px; }
  .desktop-nav { display: none; }
  .menu-toggle { display: grid; place-items: center; width: 42px; height: 42px; border: 1px solid var(--na-line); border-radius: 10px; background: white; color: var(--na-ink); }
  .mobile-nav { display: flex; flex-direction: column; gap: 0; padding: 7px 18px 20px; border-top: 1px solid var(--na-line); background: #f8f7f3; }
  .mobile-nav[hidden] { display: none; }
  .mobile-nav > a:not(.button) { padding: 13px 4px; border-bottom: 1px solid rgb(27 29 32 / 8%); color: #41444a; font-size: 13px; font-weight: 650; }
  .mobile-nav .button { margin-top: 14px; }
  .hero { min-height: 690px; min-height: clamp(640px, calc(100svh - 104px), 790px); }
  .hero-overlay { background: linear-gradient(90deg, rgb(17 19 21 / 91%) 0%, rgb(17 19 21 / 72%) 72%, rgb(17 19 21 / 58%) 100%), linear-gradient(0deg, rgb(12 13 15 / 70%) 0%, transparent 45%); }
  .hero-image { object-position: 57% center; }
  .hero-container { padding-top: 74px; padding-bottom: 25px; }
  .hero-copy-wrap { width: 100%; min-height: 430px; }
  .eyebrow { max-width: 96%; font-size: 9px; letter-spacing: .14em; }
  .hero h1 { margin-top: 24px; font-size: clamp(43px, 10.7vw, 67px); letter-spacing: -.06em; }
  .hero-description { max-width: 440px; margin-top: 22px; font-size: 14px; line-height: 1.8; }
  .hero-actions { align-items: flex-start; flex-direction: column; gap: 18px; margin-top: 28px; }
  .hero-feature { margin-top: 26px; }
  .hero-bottom-row { align-items: flex-end; }
  .hero-location { max-width: 130px; align-items: flex-start; font-size: 9px; line-height: 1.7; }
  .location-line { flex: 0 0 20px; margin-top: 6px; }
  .carousel-controls { gap: 5px; }
  .carousel-count { margin-right: 2px; }
  .carousel-progress { gap: 3px; margin-right: 3px; }
  .progress-segment { width: 18px; }
  .carousel-arrow { width: 32px; height: 32px; }
  .carousel-pause { display: none; }
  .hero-index-watermark { right: 18px; top: 45px; font-size: 10px; }
  .ribbon-inner { align-items: flex-start; flex-direction: column; gap: 13px; padding-block: 20px; }
  .ribbon-inner > span { font-size: 11px; }
  .ribbon-items { justify-content: flex-start; gap: 10px 18px; }
  .ribbon-items span { font-size: 9px; }
  .section { padding-block: 74px; }
  .section-heading { margin-bottom: 30px; }
  .section-heading-split { flex-direction: column; gap: 18px; }
  .section-heading h2, .about-copy h2, .process-intro h2, .booking-aside h2 { font-size: clamp(36px, 9vw, 49px); }
  .section-lede { font-size: 13px; }
  .services-grid { grid-template-columns: minmax(0, 1fr); }
  .service-card { min-height: 250px; padding: 24px; }
  .service-detail { margin-top: 20px; }
  .services-bottom { align-items: flex-start; flex-direction: column; gap: 10px; }
  .about-grid { grid-template-columns: minmax(0, 1fr); gap: 43px; }
  .about-visual { min-height: 375px; margin-left: 13px; padding: 0 22px 24px 0; }
  .about-visual > img { height: 355px; }
  .about-image-stamp { left: -13px; bottom: 51px; padding: 12px; }
  .about-image-stamp small { font-size: 8px; }
  .about-image-caption { right: 12px; bottom: 7px; font-size: 8px; }
  .about-copy h2 { font-size: 38px; }
  .vehicle-grid { grid-template-columns: minmax(0, 1fr); gap: 12px; margin-top: 35px; }
  .vehicle-card { padding: 24px; }
  .vehicle-card h3 { margin-top: 18px; }
  .vehicle-card p { min-height: auto; }
  .section-heading-centered .section-kicker { justify-content: flex-start; }
  .section-heading-centered { text-align: left; }
  .section-heading-centered .section-lede { margin-left: 0; }
  .process-layout { grid-template-columns: minmax(0, 1fr); gap: 38px; }
  .process-step { grid-template-columns: 32px 1fr 16px; gap: 12px; }
  .process-step h3 { font-size: 14px; }
  .booking-layout { grid-template-columns: minmax(0, 1fr); gap: 35px; }
  .booking-aside { padding-top: 0; }
  .booking-aside > p:not(.section-kicker) { max-width: 500px; }
  .contact-details { gap: 14px; margin-top: 25px; }
  .booking-note { margin-top: 22px; }
  .booking-card { padding: 23px 18px; }
  .booking-card-heading h3 { font-size: 26px; }
  .booking-heading-icon { flex-basis: 37px; width: 37px; height: 37px; }
  .form-grid { grid-template-columns: minmax(0, 1fr); gap: 15px; }
  .form-field-wide { grid-column: auto; }
  .form-field input, .form-field textarea, .form-field select { min-height: 46px; font-size: 16px; }
  .form-field textarea { min-height: 92px; }
  .closing-inner { flex-wrap: wrap; gap: 13px; }
  .closing-icon { flex-basis: 44px; width: 44px; height: 44px; }
  .closing-inner > div { flex: 1; min-width: 180px; }
  .closing-inner h2 { font-size: 22px; }
  .closing-inner .button { width: 100%; margin: 6px 0 0; }
  .footer-main { grid-template-columns: minmax(0, 1fr); gap: 20px; padding-block: 33px; }
  .footer-main > p { justify-self: start; }
  .footer-links { grid-column: auto; gap: 13px 18px; }
  .footer-bottom { flex-wrap: wrap; justify-content: flex-start; gap: 11px 22px; padding-bottom: 66px; }
  .floating-contact { right: 14px; bottom: 13px; min-height: 46px; padding-inline: 14px; }
}

@media (max-width: 380px) {
  .container { width: calc(100% - 28px); }
  .utility-inner .utility-item { font-size: 8px; }
  .brand { gap: 8px; }
  .brand-mark { width: 35px; height: 35px; }
  .brand-copy strong { font-size: 11px; }
  .brand-copy span { font-size: 8px; letter-spacing: .2em; }
  .hero h1 { font-size: 41px; }
  .carousel-count { display: none; }
  .booking-card { padding: 20px 14px; }
}

@media (hover: none), (pointer: coarse) {
  .cursor-ambient { display: none; }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { scroll-behavior: auto !important; animation-duration: .01ms !important; animation-iteration-count: 1 !important; transition-duration: .01ms !important; }
  .cursor-ambient { display: none; }
}
FILE_EOF

cat > src/test/setup.ts <<'FILE_EOF'
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach, vi } from "vitest";

afterEach(() => cleanup());

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

class TestIntersectionObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords() { return []; }
}

Object.defineProperty(globalThis, "IntersectionObserver", {
  writable: true,
  value: TestIntersectionObserver,
});
FILE_EOF

cat > src/App.test.tsx <<'FILE_EOF'
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import App from "./App";

describe("Northern Autocare KE website", () => {
  it("renders the brand and first hero slide", () => {
    render(<App />);
    expect(screen.getByRole("link", { name: /Northern Autocare KE home/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /Precision care/i })).toBeInTheDocument();
  });

  it("shows the service catalogue and appointment form", () => {
    render(<App />);
    expect(screen.getByRole("heading", { name: /Good care starts/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /Wheel balancing & alignment/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /Tell us what your vehicle needs/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/Phone number/i)).toBeInTheDocument();
  });
});
FILE_EOF

cat > index.html <<'FILE_EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="theme-color" content="#1b1d20" />
    <meta name="description" content="Northern Autocare KE in Lodwar, Turkana County: wheel balancing and alignment, computerized diagnostics, servicing, engine overhauls, mechanical repairs, and affordable spare parts." />
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Northern Autocare KE | Built for the road ahead" />
    <meta property="og:description" content="Automotive servicing, diagnostics, wheel alignment, engine repairs, and spare-parts support in Lodwar, Turkana County." />
    <meta property="og:image" content="https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=1200&q=85" />
    <title>Northern Autocare KE | Automotive Care in Lodwar</title>
    <link rel="preconnect" href="https://images.unsplash.com" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
FILE_EOF

# The build script relies on these npm scripts already being configured by setup.
node --input-type=module <<'NODE_EOF'
import fs from 'node:fs';
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts ??= {};
pkg.scripts.dev ??= 'vite';
pkg.scripts.build = 'tsc -b && vite build';
pkg.scripts.preview ??= 'vite preview';
pkg.scripts.test = 'vitest run';
pkg.scripts['test:watch'] = 'vitest';
pkg.scripts.typecheck = 'tsc -b';
if (!pkg.scripts.lint) {
  pkg.scripts.lint = fs.existsSync('node_modules/.bin/oxlint') ? 'oxlint .' : 'eslint .';
}
fs.writeFileSync('package.json', `${JSON.stringify(pkg, null, 2)}\n`);
NODE_EOF

info "Running TypeScript checks..."
npm run typecheck
info "Running component tests..."
npm run test
info "Running linter..."
npm run lint
info "Creating production build..."
npm run build

ok "Northern Autocare KE homepage built and all configured checks passed."
printf '\nNext commands:\n  cd "%s"\n  npm run dev\n\n' "$PROJECT_DIR"
printf 'Open the local URL printed by Vite, normally http://localhost:5173/\n'
printf 'Backup of replaced entry files: %s\n' "$BACKUP_DIR"
