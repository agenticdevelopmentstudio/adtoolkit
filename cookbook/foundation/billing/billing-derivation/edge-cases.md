
- Unparseable timestamps are dropped silently; if all are dropped the result is empty.
- Fractional-second stamps count as activity at their whole second; mixed stamp forms sort by instant.
- The session start may be in the space-separated form the store writes.
- A malformed session start is ignored (no lead-in).
- Time before a later run's first event is lost, not invented.

