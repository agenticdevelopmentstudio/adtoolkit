// @vitest-environment jsdom
import { describe, it, expect, afterEach } from "vitest";
import { render, cleanup } from "@testing-library/react";
import { DirectCell, UNATTRIBUTED_KEY, unattributedLast, type BreakdownRow } from "./BreakdownTable";

afterEach(cleanup);

const row = (over: Partial<BreakdownRow>): BreakdownRow => ({
  key: "k",
  label: "Acme",
  requests: 0,
  serverMs: 0,
  dbMs: 0,
  llmTokens: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, reasoning: 0 },
  directMicros: 0,
  hostingShareMicros: 0,
  estimatedMicros: 0,
  unpricedLines: 0,
  ...over,
});

describe("unattributedLast", () => {
  it("moves the nil-key row to the end and keeps the server's order otherwise", () => {
    const rows = [row({ key: "a" }), row({ key: UNATTRIBUTED_KEY }), row({ key: "b" })];
    expect(unattributedLast(rows).map((r) => r.key)).toEqual(["a", "b", UNATTRIBUTED_KEY]);
  });
});

describe("DirectCell", () => {
  it("reads null as Unpriced, a real zero as $0.00, and unpriced lines as a floor", () => {
    expect(render(<DirectCell row={row({ directMicros: null })} />).container.textContent).toBe(
      "Unpriced",
    );
    cleanup();
    expect(render(<DirectCell row={row({ directMicros: 0 })} />).container.textContent).toBe(
      "$0.00",
    );
    cleanup();
    expect(
      render(<DirectCell row={row({ directMicros: 1_500_000, unpricedLines: 2 })} />).container
        .textContent,
    ).toBe("≥ $1.50");
  });
});
