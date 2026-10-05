
- **Path deeper than one segment**: sign-in apps, feature flags, server bags, and
  storage tokens MUST return an empty result for any path longer than one segment;
  user auth MUST return an empty result for any non-empty path at all (it has no
  detail-lookup segment to descend into).
- **Unmatched id/key at depth one**: a path segment id matching no existing entity
  MUST return an empty result for all four list-based topics.
- **Malformed JSON in a server bag's value field**: the value-parsing step MUST
  discard the specific decode-error text and surface only the fixed invalid-JSON
  message, on both create and detail save.
- **Server-side duplicate after client pre-check passes**: a conflict error from
  create for flags, bags, or sign-in apps MUST be caught and re-thrown with the same
  friendly message the client-side pre-check uses, so the user sees identical
  wording regardless of which check caught the duplicate.
- **Case-insensitive sign-in-app leaf collision**: a new leaf that differs only in
  case from an existing one (e.g. "kiosk" vs. an existing "Kiosk") MUST be rejected
  by **signinapps-duplicate-leaf-check**, even though the raw strings are not equal.
- **Origin with credentials, a path, or a non-http(s) scheme**: each MUST be
  rejected by the origin-validation step with its own specific message and MUST NOT
  reach the network.
- **Re-rendering the detail currently showing a revealed secret**: MUST NOT drop the
  secret — the secret-expiry check's same-detail guard leaves it untouched; only
  navigating to a *different* destination drops it.
- **A value outside the shared error taxonomy thrown during storage-token create**:
  MUST be converted to a generic unexpected error with a fixed message, discarding
  the original error's own message text — a deliberate divergence from the shared
  error-wrapping step's usual behavior of preserving as much detail as possible (see
  Design Decisions).
- **A feature-flag key containing a reserved character (e.g. `:`)**: see the open
  question on **flags-key-charset-unrestricted** — no given implementation rejects it, but it is
  later embedded unescaped in a colon-delimited composite id.
- **Path segments containing special characters**: the alternate client's
  path-encoding step MUST percent-encode every ecosystem id, flag key, bag key, and
  sign-in-app id interpolated into a request path, so a key/id with `/`, `?`, or
  similar cannot corrupt the request path even though no character-set validation
  rejects such a key upstream.
- **The create body's own ecosystem-id field left unset while a scope parameter is
  also given**: neither implementation reconciles the two channels;
  **dual-scoping-channels** documents that the rail always leaves the body field
  unset and relies on the parameter/query channel exclusively.

