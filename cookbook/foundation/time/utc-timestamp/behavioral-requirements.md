
- **wire-form**: A written instant MUST be `yyyy-MM-ddTHH:mm:ssZ`: four-digit year, two-digit month, day, hour, minute and second, in UTC, whole seconds, no fraction, so equal-width strings sort chronologically.
- **fractions-truncate**: Writing from an instant with a fractional second MUST truncate toward the earlier second, so an instant never reads later than it happened; negative epoch values MUST floor.
- **now**: The type MUST offer the current instant as a wire string.
- **days-ago**: The wire instant `days` whole days before a reference (default now) MUST be the lower bound a recent query sends.
- **day-key**: The day key for an instant in a time zone MUST be the `yyyy-MM-dd` calendar day the instant falls on in that zone, adding the zone's offset at that instant before taking the date.
- **read-epoch-seconds**: Reading MUST return whole seconds since 1970 for any accepted shape, truncating any fraction, or nothing when the text does not parse.
- **read-date**: Reading to a date MUST include the fraction, or nothing when the text does not parse.
- **fast-path-shapes**: The fast path MUST accept `yyyy-MM-ddTHH:mm:ss[.fraction]Z` with a fraction of any width, and `yyyy-MM-dd HH:mm:ss[.SSS]` with either no fraction or exactly three digits and no zone (SQLite, UTC).
- **fast-path-validates**: The fast path MUST return nothing, so the caller falls back, for offsets, odd widths and out-of-range fields: month outside 1 to 12, day beyond the month's length including leap years, hour 24 or more, minute or second 60 or more.
- **fallback-to-shared-parser**: When the fast path declines, reading MUST fall back to the shared timestamp parser.
- **canonical**: The canonical form of any accepted shape MUST be the wire form of its whole seconds, or nothing if it does not parse, so stored instants compare as strings.
- **seconds-between**: The seconds from a start to an end text MUST be zero when either is unparseable or the end is before the start; a negative duration MUST NOT silently subtract from a total.
- **adding**: Adding a whole-second delta to a text MUST return the wire form of the moved instant, or nothing when the text does not parse.
- **civil-calendar**: Date arithmetic MUST use a proleptic Gregorian days-from-civil algorithm, not a platform calendar.

