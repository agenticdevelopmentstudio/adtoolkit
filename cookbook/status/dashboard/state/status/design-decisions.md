
**Decision**: Surface the endpoint's `error` string as the thrown message, falling back to `status <code>`.
**Rationale**: The endpoint returns the real reason (for example a DB outage) and the UI should show "WHY, not \"status 503\"". The fallback keeps a message when the body carries no reason.
**Approved**: pending

**Decision**: On the web implementation, use the API client's raw request method instead of its JSON-decoding convenience method (`StatusApiClient.json`).
**Rationale**: The convenience method would prefix the message with `GET /api/status → 503 — `; the raw path lets the state throw the bare reason string. The trade-off is that a non-string `error` (which the convenience method's `errorDetail` would unwrap via `error.message`) is coerced here to `[object Object]`.
**Approved**: pending

**Decision**: Enable refetch-on-focus and set no periodic refresh interval (on the web implementation, react-query's `refetchOnWindowFocus: true` with no `refetchInterval`).
**Rationale**: Focus refetch keeps the summary current when the operator returns to the tab; the 60-second periodic refresh is centralized in the refresh-all state so all supporting datasets refresh together.
**Approved**: pending

**Decision**: On the web implementation, return the success body by type assertion without runtime validation.
**Rationale**: The body shape is owned by the status service's endpoint in the same toolkit; consumers guard optional access (for example defaulting to an empty list). A malformed body therefore resolves rather than failing. Other platforms (for example SwiftUI's `Decodable`) validate shape instead, per Platform Notes.
**Approved**: pending

