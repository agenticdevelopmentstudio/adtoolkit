import { describe, expect, it } from "vitest";
import { dollarsToMicros, microsToDollars, shiftDecimal, toMicrosPerUnit } from "./decimal";

describe("shiftDecimal", () => {
  it("moves the point in the digits, with no float error", () => {
    expect(shiftDecimal("0.1", 6)).toBe("100000");
    expect(shiftDecimal("0.000003", 6)).toBe("3");
    expect(shiftDecimal("1.5", 3)).toBe("1500");
    expect(shiftDecimal("1234", -6)).toBe("0.001234");
    expect(shiftDecimal("007.50", 0)).toBe("7.5");
    expect(shiftDecimal(".5", 1)).toBe("5");
  });
});

describe("toMicrosPerUnit", () => {
  it("$ per 1M units is the same number of µUSD per unit", () => {
    expect(toMicrosPerUnit("3", "dollars-per-1m")).toEqual({ ok: true, value: "3" });
    expect(toMicrosPerUnit("0.15", "dollars-per-1m")).toEqual({ ok: true, value: "0.15" });
    expect(toMicrosPerUnit("15.000000000001", "dollars-per-1m")).toEqual({
      ok: true,
      value: "15.000000000001",
    });
  });

  it("$ per 1K shifts three places, $ per unit six", () => {
    expect(toMicrosPerUnit("0.003", "dollars-per-1k")).toEqual({ ok: true, value: "3" });
    expect(toMicrosPerUnit("0.000003", "dollars-per-unit")).toEqual({ ok: true, value: "3" });
    expect(toMicrosPerUnit("0.0000001", "dollars-per-unit")).toEqual({ ok: true, value: "0.1" });
  });

  it("refuses a value finer than 12 fractional digits, and accepts exactly 12", () => {
    expect(toMicrosPerUnit("1.0000000000001", "micros-per-unit").ok).toBe(false);
    expect(toMicrosPerUnit("1.000000000001", "micros-per-unit").ok).toBe(true);
    // The limit applies after the shift: 19 dollar digits is 13 µUSD digits, 18 is 12.
    expect(toMicrosPerUnit("0.0000000000000000001", "dollars-per-unit").ok).toBe(false);
    expect(toMicrosPerUnit("0.000000000000000001", "dollars-per-unit").ok).toBe(true);
  });

  it("refuses text that is not a non-negative number", () => {
    for (const bad of ["", "abc", "-1", "1e3", "1.2.3", "$5"]) {
      expect(toMicrosPerUnit(bad, "micros-per-unit").ok).toBe(false);
    }
  });
});

describe("dollarsToMicros", () => {
  it("converts to an exact integer count", () => {
    expect(dollarsToMicros("20")).toEqual({ ok: true, value: 20_000_000 });
    expect(dollarsToMicros("0.1")).toEqual({ ok: true, value: 100_000 });
    expect(dollarsToMicros("19.999999")).toEqual({ ok: true, value: 19_999_999 });
  });

  it("refuses a seventh decimal place and non-numbers", () => {
    expect(dollarsToMicros("0.0000001").ok).toBe(false);
    expect(dollarsToMicros("x").ok).toBe(false);
  });

  it("round-trips with microsToDollars", () => {
    expect(microsToDollars(1_500_000)).toBe("1.5");
    expect(microsToDollars(1)).toBe("0.000001");
    expect(microsToDollars(0)).toBe("0");
  });
});
