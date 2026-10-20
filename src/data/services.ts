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
