export const MIN_RETENTION_DAYS = 1;
export const MAX_RETENTION_DAYS = 365;

export const RETENTION_ERROR = `Retention must be a whole number of days from ${MIN_RETENTION_DAYS} to ${MAX_RETENTION_DAYS}.`;

/** The retention in days when `text` is a whole number from 1 to 365, else null. */
export function parseRetentionDays(text: string): number | null {
  const t = text.trim();
  if (!/^\d+$/.test(t)) return null;
  const n = Number(t);
  return n >= MIN_RETENTION_DAYS && n <= MAX_RETENTION_DAYS ? n : null;
}
