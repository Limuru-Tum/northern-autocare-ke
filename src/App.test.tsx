import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import App from "./App";

describe("Northern Autocare KE website", () => {
  it("renders the brand and first hero slide", () => {
    render(<App />);
    expect(screen.getByRole("link", { name: /Northern Autocare KE home/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /Precision care/i })).toBeInTheDocument();
  });

  it("shows the service catalogue and appointment form", async () => {
    render(<App />);
    expect(screen.getByRole("heading", { name: /Good care starts/i })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: /Wheel balancing & alignment/i })).toBeInTheDocument();
    expect(await screen.findByRole("heading", { name: /Tell us what your vehicle needs/i })).toBeInTheDocument();
    expect(await screen.findByLabelText(/Phone number/i)).toBeInTheDocument();
  });

  it("moves to the next hero slide with the carousel controls", async () => {
    render(<App />);
    fireEvent.click(screen.getByRole("button", { name: /Next slide/i }));
    expect(await screen.findByRole("heading", { name: /When performance matters most/i })).toBeInTheDocument();
  });
});
