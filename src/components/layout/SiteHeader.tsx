import { useState } from "react";
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
