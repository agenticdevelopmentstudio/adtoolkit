
- **Data collected**: This component collects no new personal data. It
  reads the already-stored access token's subject claim, via reading the
  token's subject claim (documented by the authentication client recipe),
  solely to compare it against the previously seen value; it never displays,
  re-derives, or persists that claim itself.
- **Storage**: The last-seen subject lives in an in-memory, module-scope
  variable — never written to a persistent or session-scoped client-side
  store, or a cookie, and gone the moment the page/module is reloaded. The
  cache entries under the long-retention key prefixes this client governs live
  only in the in-memory query cache.
- **Transmission**: This component makes no network call of its own.
- **Retention**: The last-seen subject persists only for the life of the
  browser tab holding the module; the entire query cache it guards is
  discarded outright the instant the signed-in principal changes — the
  mechanism that keeps a second principal on a shared machine from ever
  reading rows cached under the first.

