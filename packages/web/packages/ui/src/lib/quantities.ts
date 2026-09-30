/**
 * Quantities as a person reads them: counts, bytes and durations. Plain functions so every
 * surface that shows a meter, a table cell or a chart axis reads the same figure the same way.
 */

/** Calls / tokens — a plain grouped integer. */
export function formatCount(n: number): string {
  return n.toLocaleString("en-US");
}

const BYTE_UNITS = ["B", "KB", "MB", "GB", "TB"] as const;

/** Bytes, binary-scaled. Whole bytes stay whole; anything larger gets one decimal. */
export function formatBytes(n: number): string {
  let value = n;
  let unit = 0;
  while (value >= 1024 && unit < BYTE_UNITS.length - 1) {
    value /= 1024;
    unit += 1;
  }
  const rendered = unit === 0 ? String(Math.round(value)) : value.toFixed(1);
  return [rendered, BYTE_UNITS[unit]].join(" ");
}

const COMPACT = new Intl.NumberFormat("en-US", { notation: "compact", maximumFractionDigits: 1 });

/** A count shortened for a chart axis or a dense cell: `340`, `1.2K`, `3.4M`. */
export function formatCompact(n: number): string {
  return COMPACT.format(n);
}

const DURATION_UNITS: readonly (readonly [unit: string, ms: number])[] = [
  ["h", 3_600_000],
  ["min", 60_000],
  ["s", 1_000],
];

/**
 * Milliseconds of work, in the largest unit it reaches: `850 ms`, `1.2 s`, `4.5 min`, `2.0 h`.
 * Time summed over a range runs to hours, and a bare ms count that long is unreadable.
 *
 * The unit is chosen AFTER rounding to the one decimal shown, so a value just under a unit
 * boundary reads as the larger unit (`59 999 ms` is `1.0 min`, never `60.0 s`).
 * A non-finite input (no duration to show) reads `—`, the placeholder `formatMicros` uses.
 */
export function formatDuration(ms: number): string {
  if (!Number.isFinite(ms)) return "—";
  for (const [unit, size] of DURATION_UNITS) {
    const shown = Math.round((Math.abs(ms) / size) * 10) / 10;
    if (shown >= 1) return `${(Math.sign(ms) * shown).toFixed(1)} ${unit}`;
  }
  return `${Math.round(ms)} ms`;
}
