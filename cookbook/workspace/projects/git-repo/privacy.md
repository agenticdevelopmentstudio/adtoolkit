
- **Data collected**: `path` (an absolute filesystem path, which on a
  typical desktop home directory includes the user's account name) and
  `remote` (a git remote URL another component read out of `.git/config`,
  stored verbatim). Nothing in this component inspects, validates, or
  redacts the `remote` string, so if that URL happens to embed user-info
  credentials (as a bare `https://` remote URL sometimes does), it is
  stored exactly as given, with no special handling.
- **Storage**: None performed by this component — the repository record,
  the scanned repository, and the scan summary are plain in-memory value
  types with no persistence code of their own; whatever writes them to
  disk (e.g. a database component) is a separate source not given here.
- **Transmission**: None — this component makes no network call.
- **Retention**: Not defined here; a value's lifetime is entirely up to its
  caller.

