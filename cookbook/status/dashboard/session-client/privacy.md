
- **Data collected**: the signed-in user's `email`, optional `displayName`, and `role`, returned by `/auth/me`.
- **Storage**: held only in the host's in-memory cache under the session query key; nothing is written to persistent browser storage, cookies or disk by this logic. The session credential itself is the `status_auth` httpOnly cookie, which client code cannot read — this logic never touches it.
- **Transmission**: the browser attaches the cookie to the same-origin `/auth/me` and `/auth/logout` requests; this logic sends no credential or personal data in a URL or body. The header seam exposes only a display name (`displayName` or, failing that, `email`).
- **Retention**: in memory until the page unloads or the cache garbage-collects the entry; `onLogout`'s full-page navigation discards the cache.

