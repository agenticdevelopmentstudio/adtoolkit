
- **Null and empty input — identifiers**: Not checked client-side. The workspace slug, key, id,
  and the roster slug are all plain strings; an empty string is sent to the server unchanged (e.g.
  `workspace=`). A non-empty, valid slug/id/key is a caller precondition per the documented rule
  for each operation, not something this client validates.
- **rename-empty-patch-validation**: supplying at least one of `name`/`slug`/`description` is a
  caller precondition stated in the rename input's documentation; the rename operation does not
  check it, so calling rename with an empty patch sends an empty JSON object as the PATCH body, and
  the backend's response surfaces unchanged.
- **Boundary/malformed values**: No length, character-set, or format constraint is enforced
  client-side on `slug`, `name`, or `description` anywhere in this domain's operations — unlike
  the sibling Ecosystem concept's pattern/length checks, this client imposes no boundary of its own
  on any field; per the domain's own "hand-written on the backend" framing, the backend's own
  validation is the sole authority.
- **Concurrent access — competing creates**: Two closely-timed create calls for the same slug race
  the backend's unique-slug constraint; the loser's request is rejected with a 409 that the create
  operation maps to `"An organization with that slug already exists."` — this client makes no
  pre-check of its own, so both requests are always sent.
- **Concurrent access — competing restores**: Two closely-timed restore calls for handles that
  both resolve to the same freed slug race the same way; per
  `organization-restore-conflict-status-based`, the loser gets the distinct, status-based `"That
  organization's handle has been taken, so it can't be restored."` message rather than the
  create/rename wording.
- **Error states — validation vs. HTTP failure**: every error this domain's callers can observe is
  a thrown HTTP error or one of the two hand-authored friendly errors (the create/rename conflict
  remap, the restore conflict remap); no path in either operation swallows an error or resolves a
  value on failure.
- **Error states — 404 ambiguity**: per `organization-resolve-no-404-mapping` and
  `roster-not-found-semantics`, the resolve operation's 404 (key not found) and the roster's 404
  (non-org slug, or a non-member of a real org) are both plain, unremapped HTTP errors with
  `status: 404` — this client gives the caller no way to distinguish "does not exist" from "exists
  but you can't see it" beyond the status code itself.
- **Offline or disconnected state**: none of the seven exported operations catches a network-level
  connection failure; a connectivity loss mid-call propagates as an unhandled asynchronous
  rejection to the caller, with no retry, queuing, or offline-specific handling anywhere in this
  domain.
- **No timeout / no cancellation**: no operation sets a deadline or accepts a cancellation signal
  from the caller; a reachable-but-unresponsive backend leaves the call pending indefinitely.
- **No retry beyond the 401 waterfall**: every call issues exactly one request (plus, on a 401,
  the single inherited refresh-and-retry); nothing in this domain retries a network failure or a
  non-401/non-409 error status.

