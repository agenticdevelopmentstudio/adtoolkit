// Sums over the insight reports' rows, so every pane totals tokens and money the same way.

import type { InsightOverview } from "../api/insight";

type LlmTokens = InsightOverview["points"][number]["llmTokens"];

/** Input + output + cache tokens. Reasoning is already inside output, so it is not added again. */
export const llmTokenTotal = (t: LlmTokens): number =>
  t.input + t.output + t.cacheRead + t.cacheWrite;

/** A report row's direct money: µUSD (`null` when all of it is unpriced) and its unpriced lines. */
export interface PricedRow {
  directMicros: number | null;
  unpricedLines: number;
}

export interface DirectTotal {
  /** The priced rows summed; `null` when every row is unpriced (an empty range is 0). */
  directMicros: number | null;
  /** Some row has an unpriced line, so the sum leaves part out and is a floor. */
  isFloor: boolean;
}

/**
 * The direct cost over a set of rows. A row can be priced and still carry unpriced lines, so the
 * total is a floor whenever any row does — not only when a row's money is `null`.
 */
export function directTotal(rows: readonly PricedRow[]): DirectTotal {
  const priced = rows.filter((r) => r.directMicros !== null);
  return {
    directMicros:
      priced.length === 0 && rows.length > 0
        ? null
        : priced.reduce((n, r) => n + r.directMicros!, 0),
    isFloor: rows.some((r) => r.directMicros === null || r.unpricedLines > 0),
  };
}
