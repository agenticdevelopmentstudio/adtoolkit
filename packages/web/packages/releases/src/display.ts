/** A release asset's size as a downloads page shows it: megabytes, one decimal. */
export function releaseSize(bytes: number): string {
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

/**
 * A release date as a downloads page shows it ("September 28, 2026"), or the value as
 * given when it is not a date. UTC, not the host's zone: a date-only value parses as UTC
 * midnight, and a Pacific-time server would print the day before.
 */
export function releaseDate(iso: string): string {
  const parsed = new Date(iso);
  if (Number.isNaN(parsed.getTime())) return iso;
  return parsed.toLocaleDateString("en-US", {
    timeZone: "UTC",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

/**
 * A minimum system version as a reader knows it: "26.0" reads as a build number, "26" as
 * the release. Only a trailing ".0" goes — "14.2" is a real floor and is kept whole.
 */
export function releaseSystem(version: string): string {
  return version.replace(/\.0$/, "");
}
