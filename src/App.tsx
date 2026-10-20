import { useCallback, type PointerEvent } from "react";
import { ArrowRight, BadgeCheck, CarFront, Check, Clock3, MapPin, MessageCircle, ShieldCheck, Truck, Wrench } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SiteHeader } from "@/components/layout/SiteHeader";
import { HeroCarousel } from "@/components/home/HeroCarousel";
import { ServiceCard } from "@/components/services/ServiceCard";
import { DeferredAppointmentForm } from "@/components/booking/DeferredAppointmentForm";
import { business } from "@/config/business";
import { services } from "@/data/services";

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

const CURRENT_YEAR = new Date().getFullYear();

export default function App() {
  const reducedMotion = useReducedMotion();

  const handlePointerMove = useCallback((event: PointerEvent<HTMLDivElement>) => {
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
            <DeferredAppointmentForm />
          </div>
        </section>

        <section className="closing-cta"><div className="container closing-inner"><span className="closing-icon"><BadgeCheck size={24} aria-hidden="true" /></span><div><p className="section-kicker">NORTHERN AUTOCARE KE · LODWAR</p><h2>Keep your next journey in motion.</h2></div><a className="button button-dark" href="#booking">Request a service <ArrowRight aria-hidden="true" size={17} /></a></div></section>
      </main>

      <footer className="site-footer">
        <div className="container footer-main"><a className="brand brand-footer" href="#top" aria-label="Northern Autocare KE back to top"><span className="brand-mark"><Wrench aria-hidden="true" size={22} /></span><span className="brand-copy"><strong>NORTHERN</strong><span>AUTOCARE <b>KE</b></span></span></a><p>Automotive servicing, repairs, diagnostics, and spare-parts support in Lodwar.</p><div className="footer-links"><a href="#services">Services</a><a href="#about">Our approach</a><a href="#booking">Appointments</a><a href={`tel:${business.phoneDial}`}>Call workshop</a></div></div>
        <div className="container footer-bottom"><span>© {CURRENT_YEAR} Northern Autocare KE</span><span>Built for the road ahead.</span><a href="#top">Back to top ↑</a></div>
      </footer>

      <a className="floating-contact" href={`https://wa.me/${business.whatsappNumber}`} target="_blank" rel="noreferrer" aria-label="Chat with Northern Autocare KE on WhatsApp"><MessageCircle size={21} aria-hidden="true" /><span>Chat with us</span></a>
    </div>
  );
}
