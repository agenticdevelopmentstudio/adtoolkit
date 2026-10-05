
- **Data collected**: Apple side — a request's or pending user's `name`,
  `email`, `phone`, `message`/`note`; an admin's free-text note `content`
  and (display-only) `createdBy`; an invite's `channel` and `destination`.
  Web side — `email`, `password`, and `name` (via `registerWithInvite`), plus
  the `token`/`code` identifying the invite itself.
- **Storage**: None of the seven given sources persists anything locally.
  Apple's three topics and `AdminNotesRail` hold no state beyond the
  in-memory rows returned by the last `InvitationsDataSource` call, and every
  write is a pass-through to that injected data source (persistence, if any,
  is that implementation's concern, not given here). The web client's
  `password`, `token`, and `refreshToken` values are never written to
  storage by `invitations.ts` or `wire.ts` themselves — they are handed back
  to the caller unmodified, and it is that caller's own token store (not
  among these given sources) that decides whether and where `token`/
  `refreshToken` are persisted, per **token-and-password-handling**.
- **Transmission**: Apple's contact and note data travels only through the
  injected `InvitationsDataSource`'s own transport (not specified by these
  given sources). Web's `password` travels once, in the body of the single
  `registerWithInvite` POST; `token` travels in a URL query string for
  `preview` and in request bodies for `verify`/`accept`/`registerWithInvite`.
  Whether that transport is TLS-protected is an environment/deployment
  property outside these two files.
- **Retention**: Not defined in any of the seven given sources; retention of
  requests, pending users, invites, notes, and any issued token/refreshToken
  is entirely the concern of the injected `InvitationsDataSource`
  implementation (Apple) or the caller's own token store (web), neither of
  which is among these given sources.

