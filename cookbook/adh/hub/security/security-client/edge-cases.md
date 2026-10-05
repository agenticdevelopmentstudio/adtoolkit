
- **Null and empty input — group name (create/update)**: trimming an empty or all-whitespace group
  name produces `""`, which is sent to the backend unchanged; neither creating nor updating a group
  rejects it client-side.
- **Null and empty input — add-member/upsert-grant identifiers**: `memberId`, `targetId`, and `crud:
  ""` are all accepted as empty strings and sent verbatim; only `crud: ""` has documented meaning
  ("none"), per `access-crud-string-passthrough`.
- **Null and empty input — path-segment identifiers**: percent-encoding an empty group id, member-row
  id, grant id, bucket id, or token id produces an empty URL segment (e.g. `.../members/`); the
  resulting malformed request is still sent, with no client-side guard against it.
- **Boundary values — mint scope/expiry**: minting accepts any string array for `scope` and any string
  (or `null`) for `expiresAt` with no length, format, or range check; a caller-supplied malformed date
  string or an unbounded `scope` array is sent to the backend as-is.
- **Boundary values — `crud` grant string**: no minimum or maximum length, no de-duplication of
  repeated letters, and no validation that only `C`/`R`/`U`/`D` characters appear; upserting a grant
  sends whatever string the caller provides.
- **Concurrent access — module state**: neither client holds shared mutable state between calls
  (`stateless-module`), so there is nothing for two concurrent calls to race on within this component.
- **Concurrent access — competing name/member conflicts**: two concurrent group-create calls with the
  same trimmed name in the same bucket, or two concurrent add-member calls with the same member id, are
  resolved by the backend's uniqueness constraint; the loser's request receives the conflict that
  `access-group-create-conflict-friendly`/`access-member-add-conflict-friendly` translate to a friendly
  message — there is no client-side pre-check, only this post-hoc translation.
- **Concurrent access — competing grant/group writes**: two concurrent grant-upsert calls for the same
  group/target, or a group-delete racing a group-update for the same group, follow ordinary HTTP
  semantics — last response received wins, with no client-side sequencing, version check, or optimistic
  lock anywhere in either client.
- **Error states — validation failure vs. HTTP failure**: every error either client can throw carries
  an HTTP status and code (via the shared request helper) or, for the three conflict-translation sites,
  a plain error carrying only a friendly message and no status; a shared status-detection helper
  distinguishes the two by duck-typing the `.status` property.
- **Error states — dependency unavailable**: neither client catches a network-level rejection anywhere
  outside the `401` waterfall the shared request helper already provides; a DNS failure, connection
  refusal, or TLS error propagates as an unhandled promise rejection out of whichever operation was
  called.
- **Offline or disconnected state**: none of the twelve operations detects or reacts to a loss of
  connectivity mid-call; a connection dropped after the request was sent but before a response arrived
  surfaces only as the underlying network-level rejection described above.
- **No timeout**: no operation in either client sets a deadline or abort signal; a reachable-but-
  unresponsive backend leaves the call pending until the underlying transport's own limit, if any.
- **No cancellation**: no operation accepts a cancellation signal, so a caller cannot cancel an
  in-flight request through either client.
- **No retry beyond the 401 waterfall**: every call issues exactly one request (plus, on a `401`, the
  single inherited refresh-and-retry); nothing in either client retries a network failure or a non-401
  error status.
- **token-mint-retry-duplication**: minting sends a plain request with no idempotency key,
  client-generated request id, or de-duplication; a caller that retries minting after an ambiguous
  failure (a timeout or dropped connection after the first request reached the backend) sends a second
  request, which can mint a second, independently-secreted token. Unlike group-create/add-member, whose
  retries collide on a uniqueness constraint and surface a conflict, nothing in this component gives a
  retried mint an equivalent signal; any de-duplication belongs to the backend's mint route.
- **token-member-revocation-orphan**: the member-type vocabulary allows an API token to be a bucket
  access-group member (`memberType: "token"`), but the two clients never coordinate: revoking a token
  sends only the revoke request and touches no access-group-member row. Whether rows naming the revoked
  token are removed is decided by the backend's revocation handler, not by either client.

