import { describe, it, expect } from "vitest";
import { addDays, lastDays, monthRange } from "./days";

describe("days", () => {
  it("moves a day across month and year ends", () => {
    expect(addDays("2026-09-30", 1)).toBe("2026-10-01");
    expect(addDays("2026-01-01", -1)).toBe("2025-12-31");
  });

  it("gives the n days ending on today, inclusive", () => {
    expect(lastDays(30, "2026-09-30")).toEqual({ from: "2026-09-01", to: "2026-09-30" });
  });

  it("bounds a month", () => {
    expect(monthRange("2026-02")).toEqual({ from: "2026-02-01", to: "2026-02-28" });
  });
});
