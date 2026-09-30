// Money as adh's backend reports it: an integer count of µUSD (millionths of a
// dollar), or `null` when the amount is unpriced. The one formatter for it, so every
// surface agrees on how an unpriced figure and a sub-cent figure read.
//
// Integer math only: dividing a µUSD count by 1e6 as a float and handing the result to
// toFixed() drifts on half-way values (0.005 is not representable), so the rounding
// is done on the integer before any dollars exist.

const MICROS_PER_CENT = 10_000
const MICROS_PER_TEN_THOUSANDTH = 100
const WHOLE_DOLLARS = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 })

/** Integer `n / d`, rounded half away from zero, for `n >= 0` and `d > 0`. */
function roundedQuotient(n: number, d: number): number {
  const q = Math.floor(n / d)
  return n - q * d >= d / 2 ? q + 1 : q
}

/** `units` of `1 / scale` dollars as `$1,234.56`-style text, `digits` fraction digits. */
function dollars(units: number, scale: number, digits: number): string {
  const whole = Math.floor(units / scale)
  const fraction = String(units - whole * scale).padStart(digits, "0")
  return `$${WHOLE_DOLLARS.format(whole)}.${fraction}`
}

/**
 * Format a µUSD amount as dollars: `$1,234.56` at a cent or more, four decimals
 * (`$0.0012`) below a cent so small per-unit costs don't all read as `$0.00`, and
 * `—` for `null` (unpriced — never shown as a zero). Negative amounts keep a
 * leading `-`; one that rounds to zero is shown unsigned.
 *
 * Throws on a non-integer or unsafe input: the API only ever sends whole µUSD, so
 * anything else is a caller bug, not a value to guess at.
 */
export function formatMicros(micros: number | null): string {
  if (micros === null) return "—"
  if (!Number.isSafeInteger(micros)) {
    throw new RangeError(`formatMicros expects an integer µUSD count, got ${micros}`)
  }
  const magnitude = Math.abs(micros)
  const text =
    magnitude === 0 || magnitude >= MICROS_PER_CENT
      ? dollars(roundedQuotient(magnitude, MICROS_PER_CENT), 100, 2)
      : dollars(roundedQuotient(magnitude, MICROS_PER_TEN_THOUSANDTH), 10_000, 4)
  const roundedToZero = /^\$0\.0+$/.test(text)
  return micros < 0 && !roundedToZero ? `-${text}` : text
}
