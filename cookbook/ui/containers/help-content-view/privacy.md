
- **Data collected**: None — the view holds only the content struct (topic
  titles and bodies) passed to it by the caller; it originates no data of
  its own.
- **Storage**: Not applicable — the source performs no persistence of any
  kind.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source.
- **Retention**: The most recently set content is held in memory as a
  private stored property for the view's own lifetime, and is replaced (not
  appended to) on every subsequent content-setting call; nothing persists
  across app launches.

