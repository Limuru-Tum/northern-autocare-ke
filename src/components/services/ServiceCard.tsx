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
