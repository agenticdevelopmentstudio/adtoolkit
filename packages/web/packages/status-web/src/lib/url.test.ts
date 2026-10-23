import { describe, it, expect } from "vitest";
import { PLACEHOLDER_URL } from "@agentic-toolkit/deploy-platform/engine";
import { endpointLabel, siteNameForUrl } from "./url";

describe("a deploy-only monitor's placeholder URL", () => {
  it("is labelled by the monitor's name, not by \"https://\"", () => {
    expect(endpointLabel({ url: PLACEHOLDER_URL, name: "ai-processing-node" })).toBe("ai-processing-node · deploys only");
    expect(endpointLabel({ url: "https://api.example.test/health", name: "api" })).toBe("api.example.test");
  });

  it("never renames the site it belongs to", () => {
    expect(siteNameForUrl(PLACEHOLDER_URL)).toBeNull();
    expect(siteNameForUrl("https://api.example.test/health")).toBe("api.example.test");
  });
});
