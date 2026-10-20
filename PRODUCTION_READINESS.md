# Northern Autocare KE — Production Readiness Checklist

## Confirm business information before launch
- [ ] Confirm the workshop phone and WhatsApp numbers with management.
- [ ] Confirm the public address/pin and actual opening hours.
- [ ] Confirm the listed service catalogue, vehicle categories, parts availability wording, and any prices.
- [ ] Get management approval for the mission, vision, descriptions, and all claims on the site.
- [ ] Replace illustrative/stock workshop images with owned or properly licensed photographs when available.
- [ ] Confirm that the official business name and spelling are consistent everywhere.

## Appointment requests and privacy
- [ ] Send a test request to the business WhatsApp account from an actual phone.
- [ ] Verify that names, phone number, vehicle details, service, date, time, and notes are encoded correctly.
- [ ] Confirm the form states that a submitted WhatsApp message is only a request, not a confirmed appointment.
- [ ] Add a management-approved privacy notice explaining that users choose to send their details through WhatsApp.
- [ ] Do not advertise live availability, automatic confirmation, secure database storage, or an admin dashboard: the current frontend does not provide those backend capabilities.

## Technical release checks
- [ ] Run `npm run check` and resolve all errors.
- [ ] Run `npm run build` and `npm run preview`; test the preview on desktop and a real mobile device.
- [ ] Test keyboard-only navigation, visible focus, form errors, reduced-motion preferences, and color contrast.
- [ ] Check that every hero/service image loads and has appropriate alternative text.
- [ ] Confirm the production domain before adding canonical URLs and a sitemap.
- [ ] Configure HTTPS and appropriate security/cache headers on the hosting platform.
- [ ] Test external links, telephone links, WhatsApp message destination, and mobile navigation after deployment.
- [ ] Check performance in Lighthouse or PageSpeed Insights after deployment; avoid claiming a score until measured.

## Current scope
This is a static React frontend. Appointment details are prepared client-side and passed to WhatsApp only when the visitor chooses to open/send the message. There is no database, live availability checker, user account, or booking-management backend in this version.
