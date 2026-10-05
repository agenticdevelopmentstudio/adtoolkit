
- **Null and empty input**: the path is always a list supplied by the host's
  catch-all route matching, never absent in source; the request and prefix
  are required parameters with no runtime null guard. Every call site in
  source passes literal, well-typed values (one handler factory invocation
  per prefix), so this is enforced at compile time only — MUST be read this
  way, not as a runtime gap, because the prefix originates from a fixed,
  developer-authored literal rather than untrusted input.
- **Empty path**: a catch-all route matched with no trailing segments makes
  the joined path yield `''`. For the `api` prefix the target becomes
  `${backend}/${search}`; for the `auth` prefix it becomes
  `${backend}/auth/${search}`. MUST behave this way — there is no
  empty-path guard in source.
- **`API_BACKEND_URL` set to the empty string**: MUST be treated as unset
  per backend-url-empty-override-ignored above, falling through to the
  environment-mode default.
- **Environment mode set to a value other than `production` or
  `development`** (e.g. `'test'`, `'staging'`, or unset): MUST resolve to
  `'http://localhost:3000'`, identically to an explicit `'development'`,
  because the source checks only equality with `'production'` with no other
  branch.
- **Boundary values**: no numeric or length constraint exists on the path
  or on any header in source; a path with one segment and a path with
  hundreds of segments are joined the same way. Not applicable in the
  numeric sense — there is nothing in source to bound.
- **Concurrent access**: the backend forwarder and the handlers the handler
  factory returns hold no shared mutable state between invocations — the
  only module-level value is a read-only production-backend constant. Not
  applicable: each call is an independent forward with nothing to
  serialize.
- **Error states — backend responds with a non-2xx status**: MUST be
  returned to the caller unchanged, per response-returned-verbatim; this
  module inspects nothing about the status.
- **Error states — backend unreachable**: a connection failure (e.g.
  connection refused) makes the outbound request itself reject. The
  backend forwarder and the handler factory catch nothing, so the
  rejection propagates unhandled out of the request handler to the host
  runtime, which converts it to a generic framework-level error response
  with no proxy-authored message. This is what the source does, not an
  idealized description of it.
- **Offline / disconnected state**: connectivity loss between the browser
  and this proxy is handled by the platform's own HTTP layer, not by this
  module; there is no reconnection or resumption logic in source. The
  server-side analogue — the backend becoming unreachable mid-request — is
  the backend-unreachable case immediately above.
- **No retry on network failure**: the backend forwarder issues exactly one
  outbound request per incoming request and never retries a failed one
  itself. This is a deliberate layering boundary, not an oversight — a
  sibling module in this package's family (its SSO code exchange) already
  owns a one-time network-failure retry one layer up, at the caller.
- No timeout bounds the outbound request to the backend: a
  reachable-but-unresponsive backend leaves the inbound request pending
  until the hosting runtime's own request limit, if it has one; the proxy
  authors no deadline of its own.
- The outbound request in the backend forwarder is not given the inbound
  request's cancellation signal, so a browser-cancelled request does not
  cancel the in-flight backend call.
- No re-encoding of path segments: the backend forwarder builds the target
  URL by joining segments with no percent-encoding or validation of any
  segment. A segment containing a character invalid in a URL makes the
  joined string an invalid URL; the outbound request rejects with a
  construction error that neither the backend forwarder nor the handler
  factory catches, so it propagates unhandled to the host runtime the same
  way the backend-unreachable case above does.

