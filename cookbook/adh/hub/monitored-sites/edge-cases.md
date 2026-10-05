
- **Null and empty input — `workspace`**: not checked client-side in any of the twelve operations. The
  `workspace` option is optional and may be absent; an empty string is sent unchanged as `workspace=`
  (or, for the list-endpoints operation, silently omitted, since it is only appended when the option is
  truthy and an empty string is falsy). This is a MUST per the observed source; no validation exists.
- **Null and empty input — required create fields**: the create-group, create-site, and create-endpoint
  operations perform no client-side check that `name`/`slug`/`url` are non-empty; an empty string is
  sent to the backend unchanged, since the body-compaction helper only drops absent values, never an
  empty string. MUST behave this way per source.
- **Boundary values — `retentionDays`/`expectedStatus`/`checkIntervalSeconds`**: none of these numeric
  fields has a client-side minimum, maximum, or integer check; whatever number the caller supplies
  (including negative, zero, or non-integer) is sent to the backend unchanged. MUST behave this way per
  source — no declared closed set constrains these fields, unlike `kind`.
- **Boundary values — list size past the generic-CRUD 500-row cap**: generic-CRUD lists cap at 500 rows.
  The list-groups, list-sites, and list-endpoints operations accept no pagination, cursor, or limit
  parameter, and none of the three inspects the returned row count or signals truncation to the caller;
  a workspace with more than 500 groups, sites, or endpoints receives a silently incomplete list from
  any of the three. This is a fact traced directly to the source, not a gap invented by this recipe —
  see the `pagination-support` compliance finding below.
- **Concurrent access — module state**: this module holds no shared mutable state between calls (only
  the three read-only path constants and the fixed set of valid endpoint kinds), so there is nothing for
  two concurrent calls to race on within the module itself.
- **Concurrent access — competing writes**: two concurrent update-site/update-group/update-endpoint calls
  for the same `id` follow ordinary `PUT` semantics — last response received wins, with no client-side
  sequencing, optimistic-lock check, or `updatedAt`-based conflict detection in this recipe.
- **Concurrent access — reparent then list**: calling the update-site operation to move a site to a new
  group and then immediately calling the list-sites/list-endpoints operations issues two independent
  requests with no client-side cache to invalidate; the second request's freshness depends entirely on
  the backend having committed the first, which this module does not wait on beyond the first request's
  own response.
- **Error states — non-2xx response**: every non-`401` failure and every unresolved `401` throws a
  typed HTTP error carrying the HTTP status and optional code (`errors-carry-status-and-code`); nothing
  in this recipe catches or swallows that error.
- **Error states — `204` on a declared-void write**: the delete-group, delete-site, and delete-endpoint
  operations discard the response body and do not special-case `204`, so a `204` response resolves
  normally; this differs from operations that decode a JSON body, which treat `204` as an error — none
  of the create or update operations can receive a bodiless `204`, since decoding a response treats that
  as an error regardless of caller intent.
- **Offline or disconnected state**: none of the twelve operations catches a network-level connection
  failure; a connectivity loss mid-call propagates as an unhandled asynchronous rejection out of this
  module to the caller, with no retry, queuing, or offline-specific handling anywhere in this recipe.
- **No timeout**: no operation sets a deadline or cancellation signal; a reachable-but-unresponsive
  backend leaves the call pending until the underlying transport's own limit, if any.
- **No cancellation**: no operation accepts a cancellation-signal parameter, so a caller cannot cancel
  an in-flight request through this module.
- **No retry beyond the `401` waterfall**: every call issues exactly one request (plus, on a `401`, the
  single inherited refresh-and-retry); nothing in this recipe retries a network failure or a non-`401`
  error status.
- **Stale module doc comment**: this module's own top-of-file comment states "the client-side narrowing
  in the list-sites/list-endpoints operations stays as defense-in-depth," but the list-sites operation's
  implementation performs no such filter — it maps and sorts the response with no owner/workspace
  narrowing of its own; only the list-endpoints operation retains a client-side filter (on `siteId`, per
  `endpoint-list-double-filtered`). This is recorded as an observed discrepancy between the source's
  comment and its code in Design Decisions, not smoothed over.

