
- **Empty ecosystem-id string**: URL-encoding an empty string yields an
  empty string, producing a request path with a doubled slash (e.g. the
  realm-config route with no id segment); none of this component's
  operations reject an empty ecosystem id before building that path.
  MUST.
- **Empty badge/event-type id string**: the same doubling occurs in the
  item routes' second segment; neither updating/deleting a badge nor
  updating/deleting an event type rejects an empty id before building the
  path. MUST.
- **Fully-omitted update body**: updating a realm's configuration with an
  empty input sends a write with an empty-object body; every
  configuration-input field being optional means an all-omitted input is
  not rejected client-side. MUST.
- **Empty rungs list**: replacing a realm's level ladder with an empty
  list sends a body of `{ rungs: [] }`, which violates the documented
  "must start at 0" shape; the client performs no check for this and
  relies entirely on the backend's rejection. MUST.
- **Boundary season length (1 and 366 days)**: a season window's length
  is documented as bounded to `1..366` days; the client passes whatever
  numeric value the caller supplies with no client-side range check.
  MUST.
- **Boundary event-type field length (64 characters)**: an event-type
  input's `name`/`statKey` fields are documented as bounded to at most
  64 characters; same, unchecked client-side. MUST.
- **Concurrent calls**: this component holds no shared state between
  calls (**stateless-module**), so two concurrent calls — even to the
  same operation and ecosystem id — MUST NOT be serialized,
  deduplicated, or coalesced by this component; each fires its own
  independent request whose relative completion order depends on the
  network, not this component. MUST.
- **Network unreachable**: a request failure (e.g. no connectivity)
  fails before any response exists; per
  **error-propagation-unmodified**, the calling operation's result fails
  with that same underlying error, uncaught. MUST.
- **Non-2xx response**: a non-ok response is converted to a typed error
  carrying the response's status and an extracted message by the shared
  authenticated-request layer (outside these given sources, but read to
  resolve this contract); exactly one authorization failure triggers one
  token-refresh-and-retry before this conversion — one refresh and one
  retry only. MUST.
- **Offline or disconnected mid-request**: none of this component's
  operations register a retry, timeout, or a cancellation of their own; a
  request that never settles (e.g. a dropped connection) leaves the
  returned result pending for as long as the underlying request takes to
  settle. MUST.
- **Malformed or unexpected response body**: the shared request helper
  parses the response body unconditionally on an ok, non-empty response;
  a body that is not valid data rejects with that parse call's own
  error, likewise unwrapped and uncaught by any operation here. MUST.
- **Empty-body (no-content) response**: per the shared request helper's
  own guard, a no-content status throws a fixed error indicating a
  different helper should be used for endpoints with no body, rather
  than attempting to parse a body — none of the documented gamification
  routes are expected to return no content, so this path is unexercised
  by any operation here but remains reachable if the backend ever
  answered one of them that way. MUST.

