
- **local-day-in-zone**: Given a UTC instant string and a zone identifier, the clock MUST return the calendar day (`YYYY-MM-DD`) that instant falls on in that zone.
- **unparseable-instant-empty**: If the instant cannot be parsed by the shared UTC timestamp utility, the clock MUST return the empty string.
- **zone-fallback-utc**: An empty or unrecognised zone identifier MUST resolve to UTC, never to the host's current zone, so the same stored row buckets identically wherever it is read.
- **pure**: The clock MUST be a pure function of its two inputs: it holds no state, performs no I/O and does not read the current time.

