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
