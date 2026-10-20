# Northern Autocare KE

A modern, responsive automotive services website for Northern Autocare KE in Lodwar, Turkana County, Kenya.

The website helps customers explore automotive services, learn about the business, and submit appointment requests through WhatsApp.

## Features

- Responsive layouts for mobile, tablet, and desktop.
- Crimson automotive-inspired visual identity.
- Animated hero carousel with navigation controls.
- Cursor-reactive ambient background effects.
- Automotive service catalogue.
- Vehicle categories for saloon cars, 4x4 pickups, and commercial vans.
- Appointment request form with validation.
- Appointment review before sending a WhatsApp request.
- Accessibility and reduced-motion considerations.
- Search-engine metadata and production build configuration.

## Services

The website showcases these services, based on information provided about the business:

- Wheel balancing and replacement.
- Wheel alignment.
- Computerized diagnostic services.
- Routine vehicle servicing and oil changes.
- Engine overhauls and V6/diesel engine assembly.
- General mechanical repairs.
- Automotive spare parts.

Confirm all service descriptions with Northern Autocare KE before publication.

## Technology Stack

- React
- TypeScript
- Vite
- Tailwind CSS
- Motion for React
- React Router
- React Hook Form
- Zod
- Lucide React
- Vitest
- React Testing Library
- Oxlint

## Requirements

- Node.js
- npm

## Local Development

Install dependencies with `npm install`.

Start the development server with `npm run dev`.

Vite will display the local development URL in your terminal.

## Quality Checks

Run the following commands before deployment:

- `npm run typecheck`
- `npm run test`
- `npm run lint`
- `npm run build`

If the project defines an `npm run check` script, that can also be used to run its configured quality checks.

## Deployment

The project can be deployed to a static hosting platform such as GitHub Pages, Netlify, or Vercel.

For GitHub Pages, ensure the Vite base path matches the repository URL and the deployment workflow completes successfully.

The published website URL should be taken from the hosting platform after deployment.

## Appointment Requests

The current appointment flow prepares a request for the customer to send through WhatsApp.

The frontend does not currently provide a backend for:

- Persisting appointments in a database.
- Checking live workshop availability.
- Preventing double bookings.
- Automatically confirming appointments.
- Managing appointments through an administrative dashboard.

An appointment request is not confirmed until the workshop responds.

## Business Information

**Business:** Northern Autocare KE  
**Location:** Lodwar, Turkana County, Kenya

Confirm the official telephone and WhatsApp numbers, opening hours, mission, vision, and other business information directly with the company before publication.

## Development and Security

- Keep business details in a central configuration where practical.
- Never commit API keys, passwords, tokens, or other secrets.
- Use genuine or appropriately licensed images.
- Test changes on mobile and desktop.
- Verify the production build before deployment.
- Keep dependencies and development tools maintained.

## Project Status

Frontend application under development.

Future extensions may include a backend appointment system, customer records, workshop administration, and vehicle service-status tracking.

---

Built for the road ahead.
