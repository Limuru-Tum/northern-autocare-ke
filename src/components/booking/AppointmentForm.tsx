import { useEffect, useRef, useState, type ReactNode } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import {
  ArrowRight,
  CalendarDays,
  CheckCircle2,
  ClipboardCheck,
  MessageCircle,
  PencilLine,
  ShieldCheck,
} from "lucide-react";
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
  email: z.string().trim().refine((value) => value === "" || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value), "Enter a valid email address or leave this field blank."),
  vehicleType: z.string().min(1, "Choose the type of vehicle."),
  vehicleDetails: z.string().trim().min(2, "Enter your vehicle make and model."),
  registration: z.string().trim().max(20, "Keep the registration number under 20 characters."),
  service: z.string().min(1, "Choose the service you need."),
  preferredDate: z.string().min(1, "Choose a preferred date.").refine((value) => value >= todayLocal(), "Choose today or a future date."),
  preferredTime: z.string().min(1, "Choose a preferred time."),
  notes: z.string().max(500, "Keep additional details under 500 characters."),
});

type BookingValues = z.infer<typeof bookingSchema>;

const initialValues: BookingValues = {
  fullName: "",
  phone: "",
  email: "",
  vehicleType: "",
  vehicleDetails: "",
  registration: "",
  service: "",
  preferredDate: "",
  preferredTime: "",
  notes: "",
};

function FieldError({ id, message }: { id: string; message?: string }) {
  if (!message) return null;
  return <p className="field-error" id={id}>{message}</p>;
}

function ReviewItem({ label, children, wide = false }: { label: string; children: ReactNode; wide?: boolean }) {
  return (
    <div className={`booking-review-item${wide ? " booking-review-item-wide" : ""}`}>
      <dt>{label}</dt>
      <dd>{children || "Not provided"}</dd>
    </div>
  );
}

function makeWhatsAppMessage(values: BookingValues) {
  return [
    `Hello ${business.name}, I would like to request an appointment.`,
    "",
    `Name: ${values.fullName}`,
    `Phone: ${values.phone}`,
    `Email: ${values.email || "Not provided"}`,
    `Vehicle type: ${values.vehicleType}`,
    `Vehicle make and model: ${values.vehicleDetails}`,
    `Registration: ${values.registration || "Not provided"}`,
    `Service: ${values.service}`,
    `Preferred date: ${values.preferredDate}`,
    `Preferred time: ${values.preferredTime}`,
    `Additional details: ${values.notes.trim() || "None provided"}`,
    "",
    "I understand this is a request and the workshop will confirm availability.",
  ].join("\n");
}

export function AppointmentForm() {
  const [reviewValues, setReviewValues] = useState<BookingValues | null>(null);
  const formHeadingRef = useRef<HTMLHeadingElement>(null);
  const reviewHeadingRef = useRef<HTMLHeadingElement>(null);
  const hasVisitedReview = useRef(false);
  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isSubmitting },
    setValue,
  } = useForm<BookingValues>({
    resolver: zodResolver(bookingSchema),
    defaultValues: initialValues,
    shouldFocusError: true,
    mode: "onTouched",
  });
  const notesValue = watch("notes") || "";

  useEffect(() => {
    const handleServiceChoice = (event: Event) => {
      if (!(event instanceof CustomEvent) || typeof event.detail !== "string") return;
      if (!services.some((service) => service.title === event.detail)) return;
      setValue("service", event.detail, { shouldValidate: true, shouldDirty: true });
    };
    window.addEventListener("northern-autocare:choose-service", handleServiceChoice);
    return () => window.removeEventListener("northern-autocare:choose-service", handleServiceChoice);
  }, [setValue]);

  useEffect(() => {
    if (reviewValues) reviewHeadingRef.current?.focus();
    else if (hasVisitedReview.current) formHeadingRef.current?.focus();
  }, [reviewValues]);

  const onSubmit = (values: BookingValues) => {
    hasVisitedReview.current = true;
    setReviewValues(values);
  };

  const whatsappLink = reviewValues
    ? `https://wa.me/${business.whatsappNumber.replace(/\D/g, "")}?text=${encodeURIComponent(makeWhatsAppMessage(reviewValues))}`
    : "";

  return (
    <div className="booking-card">
      <div className="booking-card-heading">
        <div>
          <p className="form-kicker">APPOINTMENT REQUEST</p>
          <h3 id="booking-form-heading" ref={formHeadingRef} tabIndex={-1}>
            {reviewValues ? "Review your request." : "Tell us what your vehicle needs."}
          </h3>
        </div>
        <span className="booking-heading-icon"><MessageCircle size={22} aria-hidden="true" /></span>
      </div>
      <p className="booking-intro">
        {reviewValues
          ? "Check your details before sending them to the workshop. You can go back and make changes."
          : "Share a few details about you, your vehicle, and the service you need. You can review everything before sending it to the workshop."}
      </p>

      <div className="booking-progress" aria-label={reviewValues ? "Step 2 of 2: review request" : "Step 1 of 2: enter details"}>
        <span className={`booking-progress-step${reviewValues ? " booking-progress-complete" : ""}`}>
          <span className="booking-progress-number">{reviewValues ? <CheckCircle2 size={14} aria-hidden="true" /> : "1"}</span>
          Your details
        </span>
        <span className="booking-progress-rule" aria-hidden="true" />
        <span className={`booking-progress-step${reviewValues ? " booking-progress-current" : ""}`} aria-current={reviewValues ? "step" : undefined}>
          <span className="booking-progress-number">2</span>
          Review & send
        </span>
      </div>

      {!reviewValues ? (
        <form className="booking-form" onSubmit={handleSubmit(onSubmit)} noValidate>
          {Object.keys(errors).length > 0 && (
            <p className="form-error-summary" role="alert">
              Please check the highlighted fields before continuing.
            </p>
          )}
          <div className="form-section-heading">
            <span className="form-section-icon"><ClipboardCheck size={16} aria-hidden="true" /></span>
            <div><strong>Contact details</strong><span>How the workshop can reach you</span></div>
          </div>
          <div className="form-grid">
            <div className="form-field">
              <label htmlFor="fullName">Full name <span aria-hidden="true">*</span></label>
              <input id="fullName" autoComplete="name" placeholder="Your name" {...register("fullName")} aria-invalid={Boolean(errors.fullName)} aria-describedby={errors.fullName ? "fullName-error" : undefined} />
              <FieldError id="fullName-error" message={errors.fullName?.message} />
            </div>
            <div className="form-field">
              <label htmlFor="phone">Phone number <span aria-hidden="true">*</span></label>
              <input id="phone" type="tel" inputMode="tel" autoComplete="tel" placeholder="e.g. +254 712 345 678" {...register("phone")} aria-invalid={Boolean(errors.phone)} aria-describedby={errors.phone ? "phone-error" : undefined} />
              <FieldError id="phone-error" message={errors.phone?.message} />
            </div>
            <div className="form-field form-field-wide">
              <label htmlFor="email">Email address <span className="label-optional">Optional</span></label>
              <input id="email" type="email" inputMode="email" autoComplete="email" placeholder="you@example.com" {...register("email")} aria-invalid={Boolean(errors.email)} aria-describedby={errors.email ? "email-error" : undefined} />
              <FieldError id="email-error" message={errors.email?.message} />
            </div>
          </div>

          <div className="form-section-heading form-section-spaced">
            <span className="form-section-icon"><ShieldCheck size={16} aria-hidden="true" /></span>
            <div><strong>Vehicle & service</strong><span>Help the team prepare for your visit</span></div>
          </div>
          <div className="form-grid">
            <div className="form-field">
              <label htmlFor="vehicleType">Vehicle type <span aria-hidden="true">*</span></label>
              <select id="vehicleType" {...register("vehicleType")} aria-invalid={Boolean(errors.vehicleType)} aria-describedby={errors.vehicleType ? "vehicleType-error" : undefined}>
                <option value="">Select vehicle type</option>
                <option value="Saloon car">Saloon car</option>
                <option value="4x4 pickup">4x4 pickup</option>
                <option value="Commercial van / matatu">Commercial van / matatu</option>
                <option value="Other vehicle">Other vehicle</option>
              </select>
              <FieldError id="vehicleType-error" message={errors.vehicleType?.message} />
            </div>
            <div className="form-field">
              <label htmlFor="vehicleDetails">Vehicle make & model <span aria-hidden="true">*</span></label>
              <input id="vehicleDetails" autoComplete="off" placeholder="e.g. Toyota Hilux 2018" {...register("vehicleDetails")} aria-invalid={Boolean(errors.vehicleDetails)} aria-describedby={errors.vehicleDetails ? "vehicleDetails-error" : undefined} />
              <FieldError id="vehicleDetails-error" message={errors.vehicleDetails?.message} />
            </div>
            <div className="form-field form-field-wide">
              <label htmlFor="registration">Registration number <span className="label-optional">Optional</span></label>
              <input id="registration" autoComplete="off" placeholder="e.g. KDA 123A" {...register("registration")} aria-invalid={Boolean(errors.registration)} aria-describedby={errors.registration ? "registration-error" : undefined} />
              <FieldError id="registration-error" message={errors.registration?.message} />
            </div>
            <div className="form-field form-field-wide">
              <label htmlFor="service">Service required <span aria-hidden="true">*</span></label>
              <select id="service" {...register("service")} aria-invalid={Boolean(errors.service)} aria-describedby={errors.service ? "service-error" : undefined}>
                <option value="">Choose a service</option>
                {services.map((service) => <option key={service.id} value={service.title}>{service.title}</option>)}
              </select>
              <FieldError id="service-error" message={errors.service?.message} />
            </div>
          </div>

          <div className="form-section-heading form-section-spaced">
            <span className="form-section-icon"><CalendarDays size={16} aria-hidden="true" /></span>
            <div><strong>Preferred visit</strong><span>Your requested time is subject to workshop confirmation</span></div>
          </div>
          <div className="form-grid">
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
              <label htmlFor="notes">Describe the issue <span className="label-optional">Optional</span></label>
              <textarea id="notes" rows={4} maxLength={500} placeholder="Warning lights, sounds, symptoms, or details that may help the technician..." {...register("notes")} aria-invalid={Boolean(errors.notes)} aria-describedby={errors.notes ? "notes-error" : "notes-count"} />
              <div className="form-field-meta">
                <FieldError id="notes-error" message={errors.notes?.message} />
                <span id="notes-count" className="character-count">{notesValue.length}/500</span>
              </div>
            </div>
          </div>

          <Button variant="amber" className="button button-amber button-large booking-submit" type="submit" disabled={isSubmitting}>
            Review appointment request <ArrowRight aria-hidden="true" size={18} />
          </Button>
          <p className="form-privacy">Your information is used to prepare a message to the workshop. Nothing is sent until you choose to open WhatsApp.</p>
        </form>
      ) : (
        <section className="booking-review" aria-labelledby="booking-review-heading" aria-live="polite">
          <h4 id="booking-review-heading" ref={reviewHeadingRef} tabIndex={-1}>Check these details</h4>
          <p className="booking-review-caption">Make sure everything looks right before sending your request.</p>
          <dl className="booking-review-grid">
            <ReviewItem label="Customer name">{reviewValues.fullName}</ReviewItem>
            <ReviewItem label="Phone number">{reviewValues.phone}</ReviewItem>
            <ReviewItem label="Email address">{reviewValues.email}</ReviewItem>
            <ReviewItem label="Vehicle type">{reviewValues.vehicleType}</ReviewItem>
            <ReviewItem label="Make & model">{reviewValues.vehicleDetails}</ReviewItem>
            <ReviewItem label="Registration">{reviewValues.registration}</ReviewItem>
            <ReviewItem label="Service required" wide>{reviewValues.service}</ReviewItem>
            <ReviewItem label="Preferred date">{reviewValues.preferredDate}</ReviewItem>
            <ReviewItem label="Preferred time">{reviewValues.preferredTime}</ReviewItem>
            <ReviewItem label="Additional details" wide>{reviewValues.notes.trim()}</ReviewItem>
          </dl>
          <div className="booking-confirmation-note">
            <ShieldCheck size={18} aria-hidden="true" />
            <p>This is an appointment request, not a confirmed booking. The workshop must confirm your preferred time.</p>
          </div>
          <div className="booking-review-actions">
            <button className="button booking-edit-button" type="button" onClick={() => setReviewValues(null)}>
              <PencilLine size={16} aria-hidden="true" /> Edit details
            </button>
            <a className="button button-whatsapp booking-send-button" href={whatsappLink} target="_blank" rel="noopener noreferrer">
              Send request on WhatsApp <ArrowRight size={17} aria-hidden="true" />
            </a>
          </div>
          <p className="booking-review-footnote">WhatsApp opens in a new tab so you can review and send the prepared message.</p>
        </section>
      )}
    </div>
  );
}
