// Exact decimal-text math for the price forms. A price is a decimal STRING end to end (the
// backend stores `numeric`), so a float multiply (0.1 * 1e6) must never touch it: every
// conversion here moves the decimal point in the digits themselves.

/** The backend's cap on a per-unit rate's fractional digits. */
export const MAX_RATE_FRACTION_DIGITS = 12;

/** Dollars carry at most this many fractional digits to land on a whole µUSD. */
const DOLLAR_FRACTION_DIGITS = 6;

const DECIMAL = /^(\d+\.?\d*|\.\d+)$/;

/** What a rate input is denominated in; each one is a decimal shift onto µUSD per unit. */
export type PriceBasis = "micros-per-unit" | "dollars-per-unit" | "dollars-per-1k" | "dollars-per-1m";

export const PRICE_BASES: { id: PriceBasis; label: string; shift: number }[] = [
  { id: "micros-per-unit", label: "µUSD per unit", shift: 0 },
  { id: "dollars-per-unit", label: "$ per unit", shift: 6 },
  { id: "dollars-per-1k", label: "$ per 1K units", shift: 3 },
  // $ per million units IS µUSD per unit: the two factors of 1e6 cancel.
  { id: "dollars-per-1m", label: "$ per 1M units", shift: 0 },
];

/** `text` (a non-negative decimal) times 10^places, as canonical decimal text (no extra zeros). */
export function shiftDecimal(text: string, places: number): string {
  const [whole = "", fraction = ""] = text.split(".");
  const digits = whole + fraction;
  const point = whole.length + places;
  let int: string;
  let frac: string;
  if (point <= 0) {
    int = "";
    frac = "0".repeat(-point) + digits;
  } else if (point >= digits.length) {
    int = digits + "0".repeat(point - digits.length);
    frac = "";
  } else {
    int = digits.slice(0, point);
    frac = digits.slice(point);
  }
  int = int.replace(/^0+/, "") || "0";
  frac = frac.replace(/0+$/, "");
  return frac ? `${int}.${frac}` : int;
}

export type Converted = { ok: true; value: string } | { ok: false; message: string };

/**
 * The per-unit µUSD decimal string for `text` entered in `basis`, or why it cannot be sent: not a
 * number, or finer than the backend's 12 fractional digits (which it would refuse, so the field
 * refuses first).
 */
export function toMicrosPerUnit(text: string, basis: PriceBasis): Converted {
  const trimmed = text.trim();
  if (!DECIMAL.test(trimmed)) return { ok: false, message: "Enter a number, zero or more." };
  const shift = PRICE_BASES.find((b) => b.id === basis)!.shift;
  const value = shiftDecimal(trimmed, shift);
  const fraction = value.split(".")[1] ?? "";
  if (fraction.length > MAX_RATE_FRACTION_DIGITS) {
    return {
      ok: false,
      message: `That is finer than ${MAX_RATE_FRACTION_DIGITS} decimal places of a µUSD per unit.`,
    };
  }
  return { ok: true, value };
}

/** Monthly dollars to a whole µUSD count; at most 6 decimal places of a dollar. */
export function dollarsToMicros(text: string): { ok: true; value: number } | { ok: false; message: string } {
  const trimmed = text.trim();
  if (!DECIMAL.test(trimmed)) return { ok: false, message: "Enter an amount in dollars." };
  const micros = shiftDecimal(trimmed, DOLLAR_FRACTION_DIGITS);
  if (micros.includes(".")) {
    return { ok: false, message: `Use at most ${DOLLAR_FRACTION_DIGITS} decimal places.` };
  }
  const value = Number(micros);
  if (!Number.isSafeInteger(value)) return { ok: false, message: "That amount is too large." };
  return { ok: true, value };
}

/** A whole µUSD count as plain dollars text (`1500000` -> `1.5`), for an edit field. */
export function microsToDollars(micros: number): string {
  return shiftDecimal(String(micros), -DOLLAR_FRACTION_DIGITS);
}
