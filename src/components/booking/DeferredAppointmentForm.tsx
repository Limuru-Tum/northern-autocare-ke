import { lazy, Suspense, useEffect, useRef, useState } from "react";
import { Wrench } from "lucide-react";

const AppointmentForm = lazy(() =>
  import("./AppointmentForm").then((module) => ({ default: module.AppointmentForm })),
);

function BookingFormPlaceholder({ message, loading = false }: { message: string; loading?: boolean }) {
  return (
    <div className="booking-card booking-loading" role={loading ? "status" : undefined} aria-live={loading ? "polite" : undefined}>
      <span className="booking-loading-mark"><Wrench size={22} aria-hidden="true" /></span>
      <span className="booking-loading-dot" aria-hidden="true" />
      <strong>{message}</strong>
      <span>{loading ? "Preparing the appointment form." : "The form loads automatically as you approach this section."}</span>
    </div>
  );
}

/** Load form code only when the booking section is near the visible viewport. */
export function DeferredAppointmentForm() {
  const boundaryRef = useRef<HTMLDivElement>(null);
  const [shouldLoad, setShouldLoad] = useState(
    () => typeof window === "undefined" || typeof IntersectionObserver === "undefined",
  );

  useEffect(() => {
    if (shouldLoad) return;
    const boundary = boundaryRef.current;
    if (!boundary || typeof IntersectionObserver === "undefined") return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          setShouldLoad(true);
          observer.disconnect();
        }
      },
      { rootMargin: "420px 0px" },
    );
    observer.observe(boundary);
    return () => observer.disconnect();
  }, [shouldLoad]);

  return (
    <div className="booking-form-boundary" ref={boundaryRef}>
      {shouldLoad ? (
        <Suspense fallback={<BookingFormPlaceholder message="Preparing your appointment form…" loading />}>
          <AppointmentForm />
        </Suspense>
      ) : (
        <BookingFormPlaceholder message="Appointment booking, made simple." />
      )}
    </div>
  );
}
