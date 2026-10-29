import { describe, expect, it } from "vitest";

import { TYPEGEN_ONLY_FLAG, TYPEGEN_ONLY_ORIGIN, isTypegenOnly } from "../index.js";

/**
 * `next typegen` loads next.config under PHASE_PRODUCTION_BUILD, the same phase as
 * `next build`, so nothing Next hands a config can tell the two apart. The workspace
 * typecheck (`typecheck-all.py`) sets `TYPEGEN_ONLY=1` for typegen alone, and this is
 * the one reader of it. Only the exact value counts: anything looser would let a stray
 * `TYPEGEN_ONLY=0` or `=false` switch a real build's guard off.
 */
describe("isTypegenOnly", () => {
  it("is true only when the flag is exactly 1", () => {
    expect(isTypegenOnly({ [TYPEGEN_ONLY_FLAG]: "1" })).toBe(true);
  });

  it.each([undefined, "", "0", "false", "true", "yes", " 1"])(
    "is false for %j, so `next build` and `next dev` keep their guard",
    (value) => {
      expect(isTypegenOnly({ [TYPEGEN_ONLY_FLAG]: value })).toBe(false);
    },
  );

  it("is false with no flag at all, as under `next build` and `next dev`", () => {
    expect(isTypegenOnly({ NODE_ENV: "production" })).toBe(false);
    expect(isTypegenOnly({ NODE_ENV: "development" })).toBe(false);
  });

  it("names the flag typecheck-all.py sets", () => {
    expect(TYPEGEN_ONLY_FLAG).toBe("TYPEGEN_ONLY");
  });

  it("offers an origin no request can reach: the .invalid TLD never resolves", () => {
    expect(new URL(TYPEGEN_ONLY_ORIGIN).hostname.endsWith(".invalid")).toBe(true);
  });
});
