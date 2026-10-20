#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="${PROJECT_DIR:-$HOME/Desktop/northern-autocare-ke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Desktop/northern-autocare-ke-booking-mobile-backup-$STAMP}"

log() { printf '[%s] %s\n' "$1" "$2"; }
fail() { log error "$1" >&2; exit 1; }

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" ]] || fail "package.json is missing; no changes made."
[[ -f "$PROJECT_DIR/src/components/booking/AppointmentForm.tsx" ]] || fail "AppointmentForm.tsx is missing; no changes made."
[[ -f "$PROJECT_DIR/src/index.css" ]] || fail "src/index.css is missing; no changes made."
[[ -f "$PROJECT_DIR/src/config/business.ts" ]] || fail "src/config/business.ts is missing; no changes made."
[[ -f "$PROJECT_DIR/src/data/services.ts" ]] || fail "src/data/services.ts is missing; no changes made."
command -v python3 >/dev/null 2>&1 || fail "Python 3 is required."
command -v node >/dev/null 2>&1 || fail "Node.js is required."
command -v npm >/dev/null 2>&1 || fail "npm is required."

mkdir -p "$BACKUP_DIR"
for file in src/components/booking/AppointmentForm.tsx src/index.css package.json; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp -p "$PROJECT_DIR/$file" "$BACKUP_DIR/$file"
done
if [[ -f "$PROJECT_DIR/src/components/booking/AppointmentForm.test.tsx" ]]; then
  mkdir -p "$BACKUP_DIR/src/components/booking"
  cp -p "$PROJECT_DIR/src/components/booking/AppointmentForm.test.tsx" "$BACKUP_DIR/src/components/booking/AppointmentForm.test.tsx"
fi
log backup "Saved current booking, styling, and package settings to $BACKUP_DIR"

# Fail safely if this is not the expected React application; do not overwrite unknown files.
python3 - "$PROJECT_DIR" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
form = (root / "src/components/booking/AppointmentForm.tsx").read_text()
css = (root / "src/index.css").read_text()
for marker, content, label in [
    ("export function AppointmentForm", form, "AppointmentForm component"),
    (".booking-card", css, "booking-card CSS"),
]:
    if marker not in content:
        raise SystemExit(f"[error] Expected {label} was not found. No source files were rewritten.")
config = (root / "src/config/business.ts").read_text()
if "whatsappNumber" not in config or "phoneDisplay" not in config:
    raise SystemExit("[error] Business config does not expose whatsappNumber and phoneDisplay. No source files were rewritten.")
services = (root / "src/data/services.ts").read_text()
if "export const services" not in services:
    raise SystemExit("[error] Service catalogue structure was not recognized. No source files were rewritten.")
print("[ok] Existing project structure recognized")
PY

cd "$PROJECT_DIR"

cat > src/components/booking/AppointmentForm.tsx <<'TSX_EOF'
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
    reset,
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
TSX_EOF

if ! grep -q 'Booking flow + mobile-first finishing layer — Northern Autocare KE' src/index.css; then
cat >> src/index.css <<'CSS_EOF'

/* Booking flow + mobile-first finishing layer — Northern Autocare KE */
.booking-card,
.booking-form,
.form-grid,
.form-field { min-width: 0; }
.booking-card { overflow: hidden; }
.booking-progress {
  display: flex; align-items: center; gap: 9px; margin: 0 0 24px;
}
.booking-progress-step {
  display: inline-flex; align-items: center; gap: 8px; min-width: 0;
  padding: 8px 11px; border: 1px solid rgb(60 42 51 / 10%); border-radius: 999px;
  background: #f2f0f2; color: #716a72; font-size: 10px; font-weight: 750; line-height: 1.25;
}
.booking-progress-number {
  display: inline-grid; place-items: center; flex: 0 0 21px; width: 21px; height: 21px;
  border-radius: 50%; background: #e3dfe3; color: #655b63; font-size: 10px; font-weight: 850;
}
.booking-progress-step[aria-current="step"] { border-color: rgb(200 16 46 / 22%); background: #fff0f2; color: #9f1239; }
.booking-progress-step[aria-current="step"] .booking-progress-number,
.booking-progress-complete .booking-progress-number { background: #c8102e; color: #fff; }
.booking-progress-rule { width: clamp(12px, 4vw, 38px); height: 1px; flex: 0 1 38px; background: #ddd5da; }
.form-section-heading { display: flex; align-items: center; gap: 11px; margin: 21px 0 15px; }
.form-section-heading:first-of-type { margin-top: 0; }
.form-section-spaced { margin-top: 27px; }
.form-section-icon {
  display: grid; place-items: center; flex: 0 0 34px; width: 34px; height: 34px;
  border: 1px solid rgb(200 16 46 / 14%); border-radius: 10px;
  background: #fff0f2; color: #c8102e;
}
.form-section-heading strong { display: block; color: #29242a; font-size: 12px; font-weight: 850; letter-spacing: -.015em; }
.form-section-heading span:not(.form-section-icon) { display: block; margin-top: 3px; color: #858087; font-size: 10px; line-height: 1.5; }
.form-error-summary { margin: 0 0 16px; padding: 11px 13px; border: 1px solid #f0c2cb; border-radius: 10px; background: #fff2f4; color: #9f1239; font-size: 12px; line-height: 1.5; }
.form-field input,
.form-field textarea,
.form-field select { max-width: 100%; min-width: 0; border-radius: 10px; }
.form-field input:focus,
.form-field textarea:focus,
.form-field select:focus { border-color: #c8102e; box-shadow: 0 0 0 3px rgb(200 16 46 / 12%); }
.form-field [aria-invalid="true"] { border-color: #b4233c; background-color: #fffafb; }
.form-field [aria-invalid="true"]:focus { box-shadow: 0 0 0 3px rgb(180 35 60 / 12%); }
.form-field-meta { display: flex; align-items: flex-start; justify-content: space-between; gap: 10px; }
.character-count { flex: 0 0 auto; margin: 6px 0 0 auto; color: #8b838b; font-size: 10px; font-variant-numeric: tabular-nums; }
.booking-submit { gap: 10px; border-radius: 11px; }
.form-privacy { max-width: 480px; margin-inline: auto; }
.booking-review { padding: clamp(16px, 2.8vw, 24px); border: 1px solid rgb(48 34 42 / 10%); border-radius: 16px; background: #fff; box-shadow: 0 10px 28px rgb(27 15 22 / 5%); }
.booking-review h4 { margin: 0; color: #29232a; font-size: clamp(20px, 2.4vw, 25px); font-weight: 850; line-height: 1.2; letter-spacing: -.04em; }
.booking-review-caption { margin: 7px 0 19px; color: #746e75; font-size: 12px; line-height: 1.7; }
.booking-review-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0; margin: 0; border-top: 1px solid #eee8ec; }
.booking-review-item { min-width: 0; padding: 14px 12px 13px 0; border-bottom: 1px solid #eee8ec; }
.booking-review-item:nth-child(even) { padding-left: 13px; border-left: 1px solid #eee8ec; }
.booking-review-item-wide { grid-column: 1 / -1; padding-left: 0 !important; border-left: 0 !important; }
.booking-review-item dt { margin: 0 0 5px; color: #8b8089; font-size: 9px; font-weight: 850; letter-spacing: .1em; text-transform: uppercase; }
.booking-review-item dd { margin: 0; color: #2a252b; font-size: 12px; font-weight: 700; line-height: 1.6; overflow-wrap: anywhere; white-space: pre-wrap; }
.booking-confirmation-note { display: flex; align-items: flex-start; gap: 10px; margin-top: 17px; padding: 12px; border: 1px solid rgb(200 16 46 / 13%); border-radius: 11px; background: #fff5f6; }
.booking-confirmation-note svg { flex: 0 0 auto; margin-top: 1px; color: #c8102e; }
.booking-confirmation-note p { margin: 0; color: #6e4e59; font-size: 11px; line-height: 1.65; }
.booking-review-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 20px; }
.booking-edit-button { border-color: #ded6dc; background: #fff; color: #3a3038; box-shadow: none; }
.booking-edit-button:hover { border-color: #c8102e; background: #fff5f6; color: #9f1239; }
.booking-send-button { flex: 1 1 220px; justify-content: center; gap: 10px; min-height: 50px; border-radius: 11px; }
.booking-review-footnote { margin: 11px 0 0; color: #8b838b; font-size: 10px; line-height: 1.6; text-align: center; }

/* Tablet navigation: switch to the accessible menu before desktop links get cramped. */
@media (max-width: 860px) {
  .desktop-nav { display: none !important; }
  .menu-toggle { display: grid !important; place-items: center; flex: 0 0 44px; width: 44px; height: 44px; border: 1px solid rgb(46 35 43 / 13%); border-radius: 12px; background: #fff; color: #30252d; }
  .menu-toggle:focus-visible { outline: 3px solid #e11d48; outline-offset: 3px; }
  .mobile-nav { display: flex; flex-direction: column; gap: 0; padding: 8px max(22px, calc((100vw - 800px) / 2)) 20px; border-top: 1px solid rgb(48 34 42 / 9%); background: rgb(255 255 255 / 98%); box-shadow: 0 18px 28px rgb(29 13 22 / 10%); }
  .mobile-nav[hidden] { display: none !important; }
  .mobile-nav > a:not(.button) { display: block; min-height: 46px; padding: 14px 3px; border-bottom: 1px solid rgb(48 34 42 / 8%); color: #4b4149; font-size: 13px; font-weight: 750; }
  .mobile-nav > a:not(.button):hover { color: #c8102e; }
  .mobile-nav .button { justify-content: center; margin-top: 14px; }
  .header-inner { gap: 14px; }
  .booking-layout { grid-template-columns: minmax(0, 1fr); gap: 28px; }
  .booking-aside { max-width: 720px; }
  .booking-note { max-width: 620px; }
}

@media (max-width: 720px) {
  html { scroll-padding-top: 78px; }
  .container { width: calc(100% - 34px); }
  .utility-inner { display: flex; justify-content: space-between; gap: 10px; }
  .utility-inner .utility-item { min-width: 0; font-size: 9px; }
  .utility-inner .utility-item:first-child { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .utility-phone { flex: 0 0 auto; }
  .brand { min-width: 0; gap: 9px; }
  .brand-copy { min-width: 0; }
  .hero { min-height: max(620px, calc(100svh - 100px)); }
  .hero-container { padding-top: clamp(48px, 9vh, 72px); }
  .hero-copy-wrap { min-height: 0; padding-bottom: 34px; }
  .hero h1 { max-width: 100%; font-size: clamp(41px, 10vw, 62px); overflow-wrap: anywhere; }
  .hero-actions { width: 100%; align-items: stretch; }
  .hero-actions .button { width: min(100%, 360px); }
  .hero-bottom-row { flex-wrap: wrap; gap: 14px; }
  .carousel-controls { max-width: 100%; }
  .services-grid { grid-template-columns: minmax(0, 1fr); }
  .about-grid, .process-layout, .booking-layout { grid-template-columns: minmax(0, 1fr); }
  .form-grid { grid-template-columns: minmax(0, 1fr); gap: 15px; }
  .form-field-wide { grid-column: auto; }
  .form-field input, .form-field textarea, .form-field select { min-height: 48px; font-size: 16px; }
  .form-field textarea { min-height: 110px; }
  .booking-card { padding: clamp(17px, 5vw, 24px); border-radius: 18px; }
  .booking-card-heading { gap: 12px; }
  .booking-card-heading h3 { font-size: clamp(23px, 6.6vw, 28px); overflow-wrap: anywhere; }
  .booking-heading-icon { flex-basis: 38px; width: 38px; height: 38px; border-radius: 12px; }
  .booking-progress { gap: 5px; margin-bottom: 20px; }
  .booking-progress-step { gap: 6px; padding: 7px 9px; font-size: 9px; }
  .booking-progress-number { flex-basis: 19px; width: 19px; height: 19px; }
  .booking-progress-rule { flex-basis: 12px; width: 12px; }
  .form-section-heading { align-items: flex-start; }
  .form-section-heading span:not(.form-section-icon) { font-size: 10px; }
  .booking-submit { width: 100%; white-space: normal; line-height: 1.3; padding: 12px 15px; }
  .booking-review { padding: 16px 13px; }
  .booking-review-grid { grid-template-columns: minmax(0, 1fr); }
  .booking-review-item,
  .booking-review-item:nth-child(even),
  .booking-review-item-wide { grid-column: auto; padding: 12px 0; border-left: 0; }
  .booking-review-actions { flex-direction: column-reverse; }
  .booking-review-actions .button { width: 100%; min-height: 49px; }
  .booking-review-footnote { text-align: left; }
  .closing-inner { flex-wrap: wrap; }
  .closing-inner .button { width: 100%; margin-left: 0; }
  .footer-main { grid-template-columns: minmax(0, 1fr); }
  .footer-links { grid-column: auto; }
  .footer-bottom { flex-wrap: wrap; justify-content: flex-start; gap: 11px 18px; }
  .floating-contact { right: 12px; bottom: max(12px, env(safe-area-inset-bottom)); }
}

@media (max-width: 420px) {
  .container { width: calc(100% - 28px); }
  .utility-item { letter-spacing: 0; }
  .utility-inner .utility-item:first-child svg { flex: 0 0 auto; }
  .utility-phone { font-size: 8px !important; }
  .brand-mark { flex: 0 0 36px; width: 36px; height: 36px; }
  .brand-copy strong { font-size: 11px; }
  .brand-copy span { font-size: 8px; letter-spacing: .16em; }
  .menu-toggle { flex-basis: 40px; width: 40px; height: 40px; }
  .hero h1 { font-size: clamp(38px, 10.5vw, 46px); }
  .booking-progress-step { gap: 5px; padding: 7px 8px; font-size: 8px; }
  .booking-progress-rule { flex-basis: 8px; width: 8px; }
  .booking-intro { font-size: 11px; }
  .form-section-heading strong { font-size: 11px; }
  .form-section-heading span:not(.form-section-icon) { max-width: 240px; font-size: 9px; }
}

@media (hover: none), (pointer: coarse), (prefers-reduced-motion: reduce) {
  .service-card:hover, .vehicle-card:hover, .button:hover { transform: none; }
}
CSS_EOF
else
  log skip "Responsive booking/mobile CSS already exists"
fi

cat > src/components/booking/AppointmentForm.test.tsx <<'TEST_EOF'
import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { AppointmentForm } from "./AppointmentForm";

function localToday() {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

describe("AppointmentForm", () => {
  it("validates details, reviews them, and prepares a WhatsApp request", async () => {
    render(<AppointmentForm />);

    fireEvent.change(screen.getByLabelText(/Full name/i), { target: { value: "Amina Test" } });
    fireEvent.change(screen.getByLabelText(/Phone number/i), { target: { value: "+254 712 345 678" } });
    fireEvent.change(screen.getByLabelText(/Email address/i), { target: { value: "amina@example.com" } });
    fireEvent.change(screen.getByLabelText(/Vehicle type/i), { target: { value: "Saloon car" } });
    fireEvent.change(screen.getByLabelText(/Vehicle make & model/i), { target: { value: "Toyota Corolla 2018" } });
    fireEvent.change(screen.getByLabelText(/Service required/i), { target: { value: "Wheel balancing & alignment" } });
    fireEvent.change(screen.getByLabelText(/Preferred date/i), { target: { value: localToday() } });
    fireEvent.change(screen.getByLabelText(/Preferred time/i), { target: { value: "10:00 AM – 12:00 PM" } });

    fireEvent.click(screen.getByRole("button", { name: /Review appointment request/i }));

    expect(await screen.findByRole("heading", { name: /Check these details/i })).toBeInTheDocument();
    expect(screen.getByText("Toyota Corolla 2018")).toBeInTheDocument();
    expect(screen.getByText("amina@example.com")).toBeInTheDocument();

    const whatsappLink = screen.getByRole("link", { name: /Send request on WhatsApp/i });
    expect(whatsappLink).toHaveAttribute("href", expect.stringContaining("https://wa.me/"));
    expect(whatsappLink.getAttribute("href")).toContain(encodeURIComponent("Toyota Corolla 2018"));

    fireEvent.click(screen.getByRole("button", { name: /Edit details/i }));
    expect(screen.getByRole("heading", { name: /Tell us what your vehicle needs/i })).toBeInTheDocument();
    expect(screen.getByLabelText(/Vehicle make & model/i)).toHaveValue("Toyota Corolla 2018");
  });

  it("shows validation messages for missing required fields", async () => {
    render(<AppointmentForm />);
    fireEvent.click(screen.getByRole("button", { name: /Review appointment request/i }));
    expect(await screen.findByText(/Enter your name so the workshop knows who to contact/i)).toBeInTheDocument();
    expect(screen.getByRole("alert")).toHaveTextContent(/highlighted fields/i);
  });
});
TEST_EOF

# Keep lint output focused on application source so historical backup folders do not get linted.
node --input-type=module <<'NODE_EOF'
import fs from 'node:fs';
const path = 'package.json';
const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
pkg.scripts ??= {};
if (pkg.scripts.lint === 'oxlint .') pkg.scripts.lint = 'oxlint src';
else if (pkg.scripts.lint === 'eslint .') pkg.scripts.lint = 'eslint src';
fs.writeFileSync(path, `${JSON.stringify(pkg, null, 2)}\n`);
NODE_EOF

# Mark this responsive layer as idempotent and refuse duplicate appends on reruns.
# (The marker was appended above; this check validates the resulting stylesheet.)
if ! grep -q 'Booking flow + mobile-first finishing layer — Northern Autocare KE' src/index.css; then
  fail "Responsive CSS layer was not written. Original files are backed up at: $BACKUP_DIR"
fi

run_check() {
  local label="$1"; shift
  log check "$label"
  if "$@"; then log ok "$label passed"; else fail "$label failed. Review the output above; originals are backed up at: $BACKUP_DIR"; fi
}

run_check "TypeScript" npm run typecheck
run_check "Vitest" npm run test
run_check "Lint" npm run lint
run_check "Production build" npm run build

log done "Appointment review flow and responsive layout applied."
log done "Backup: $BACKUP_DIR"
