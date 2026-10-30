import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { siteProdUrl } from "@agentic-toolkit/adh-registry";
import { LandingFooter } from "../marketing/LandingFooter";

afterEach(cleanup);

function hrefs(): string[] {
  return [...document.querySelectorAll("a")].map((a) => a.getAttribute("href") ?? "");
}

describe("LandingFooter", () => {
  it("links neither Shipr nor the Registry", () => {
    render(<LandingFooter />);
    expect(hrefs()).not.toContain(siteProdUrl("shipr", "/"));
    expect(hrefs()).not.toContain(siteProdUrl("registry", "/"));
  });

  it("links FishLamp Design once, and not its second domain", () => {
    render(<LandingFooter />);
    expect(hrefs().filter((h) => h === siteProdUrl("fishlamp", "/"))).toHaveLength(1);
    expect(hrefs()).not.toContain(siteProdUrl("fishlampdesign", "/"));
  });

  it("still links the hub", () => {
    render(<LandingFooter />);
    expect(hrefs()).toContain(siteProdUrl("hub", "/"));
  });
});
