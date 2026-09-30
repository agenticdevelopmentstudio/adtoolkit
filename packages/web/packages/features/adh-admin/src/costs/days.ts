// UTC calendar days as `YYYY-MM-DD` text, the form the insight routes take and return.

/** Today (UTC), the day the backend defaults a new rate to. */
export function todayUtc(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}

/** The `YYYY-MM` month of a day. */
export const monthOf = (day: string): string => day.slice(0, 7);

/** A `YYYY-MM` month's first and last day. */
export function monthRange(month: string): { from: string; to: string } {
  const [year, mon] = month.split("-").map(Number) as [number, number];
  // Day 0 of the next month is the last day of this one.
  const last = new Date(Date.UTC(year, mon, 0)).getUTCDate();
  return { from: `${month}-01`, to: `${month}-${String(last).padStart(2, "0")}` };
}
