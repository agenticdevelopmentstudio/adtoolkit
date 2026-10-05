
- **Null and empty input**: The endpoint mapper MUST turn an absent
  `environment`, `platform`, `deployProject`, or `expectBody` into `null`,
  and an absent `ignoreProjectWarning` into `false`
  (endpoint-optional-field-defaults, endpoint-ignore-warning-default).
  Marking an empty batch of projects ignored MUST resolve immediately with
  no request issued. Listing endpoints by site, or un-ignoring a project,
  perform no client-side check that the site identifier/platform/project
  name is non-empty before URL-encoding it into the request; an empty
  string is sent to the backend as-is.
- **Boundary values**: none of `retentionDays`, `checkIntervalSeconds`, or
  `expectedStatus` is range-checked by this client before being sent;
  `environment` and `platform` are typed against a fixed set of allowed
  values but, like `kind` (see endpoint-kind-required), nothing in the
  monitoring-configuration client validates membership in either set before
  a request is sent.
- **Concurrent access**: no two calls into this client interleave against
  the same value in this component's own state; the client itself holds
  only its base path and a resolved network-request function, so multiple
  concurrent JSON-request/request/open-event-stream calls are independent,
  each with its own closure of state. The fan-out in ignore-project-fanout
  deliberately issues its N requests concurrently; when one rejects, the
  already-issued sibling requests continue running to completion in the
  background, but neither their results nor their errors are surfaced.
  (This assumes a single-threaded execution model; see Platform Notes for
  what a multi-threaded port needs.)
- **Error states**: a non-ok response from any of these operations MUST
  surface as the crafted error from json-error-message/json-error-detail. A
  network-level failure — the underlying request itself failing because it
  never reached a server (offline, DNS failure, a blocked cross-origin
  request) — is caught nowhere in this component; it propagates to the
  caller as whatever error the underlying network layer produces, which is
  a different shape than the `${method} ${url} → ${status}` message a
  non-ok response produces.
- **Offline or disconnected state**: the same uncaught-network-failure
  behavior above covers a request made while offline. For the
  open-event-stream operation, this component only opens the connection;
  reconnection after the connection drops is entirely the underlying
  Server-Sent-Events implementation's own behavior — none of these
  operations listens for or reacts to a stream error event, or re-opens the
  connection itself.

