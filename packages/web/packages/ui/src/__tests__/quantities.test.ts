import { describe, expect, it } from "vitest";
import { formatBytes, formatCompact, formatCount, formatDuration } from "../lib/quantities";

describe("formatBytes / formatCount", () => {
  it("scales bytes binary and keeps whole bytes whole", () => {
    expect(formatBytes(0)).toBe("0 B");
    expect(formatBytes(512)).toBe("512 B");
    expect(formatBytes(2048)).toBe("2.0 KB");
    expect(formatBytes(5 * 1024 * 1024)).toBe("5.0 MB");
  });

  it("groups counts", () => {
    expect(formatCount(1234567)).toBe("1,234,567");
  });
});

describe("formatCompact", () => {
  it("shortens large counts and leaves small ones", () => {
    expect(formatCompact(340)).toBe("340");
    expect(formatCompact(1_200_000)).toBe("1.2M");
  });
});

describe("formatDuration", () => {
  it("reads milliseconds in the largest unit reached", () => {
    expect(formatDuration(0)).toBe("0 ms");
    expect(formatDuration(850)).toBe("850 ms");
    expect(formatDuration(1_200)).toBe("1.2 s");
    expect(formatDuration(270_000)).toBe("4.5 min");
    expect(formatDuration(7_200_000)).toBe("2.0 h");
  });

  // The unit is picked after rounding: a value that rounds up to a whole next unit reads in it.
  it("never shows a unit's boundary in the smaller unit", () => {
    expect(formatDuration(59_999)).toBe("1.0 min");
    expect(formatDuration(3_599_999)).toBe("1.0 h");
    expect(formatDuration(999.7)).toBe("1.0 s");
  });
});
