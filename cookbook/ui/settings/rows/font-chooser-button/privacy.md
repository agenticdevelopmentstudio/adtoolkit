
- **Data collected**: None of its own. The component holds only the font
  last given to it and an optional change-callback reference supplied by
  the caller.
- **Storage**: Not applicable — source performs no read/write to disk or
  any other store (see **font-persistence**); persistence, if any, is
  entirely the caller's responsibility.
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: The component retains its selected font and change
  callback only for its own in-memory lifetime, and only until the next
  time it is given a new font, which replaces the selected font.

