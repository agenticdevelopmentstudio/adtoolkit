
- **backend-url-explicit-override**: Backend-URL resolution MUST return the
  `API_BACKEND_URL` environment value verbatim when it is a non-empty
  string, regardless of the runtime environment mode.
- **backend-url-empty-override-ignored**: Backend-URL resolution MUST treat
  an empty-string `API_BACKEND_URL` as unset and fall through to the
  environment-mode-based default, because the check is a plain truthiness
  test.
- **backend-url-production-default**: When `API_BACKEND_URL` is unset (or
  empty) and the runtime environment mode is exactly the string
  `production`, backend-URL resolution MUST return
  `https://api.agenticdeveloperhub.com`.
- **backend-url-development-default**: When `API_BACKEND_URL` is unset (or
  empty) and the runtime environment mode is anything other than exactly
  `production` (including unset or any other string), backend-URL
  resolution MUST return `http://localhost:3000`.
- **api-prefix-strips-namespace**: For the `api` prefix, the backend
  forwarder MUST build the backend target with no `api/` segment inserted,
  because the backend already dropped its own `/api` route prefix.
- **auth-prefix-preserved**: For the `auth` prefix, the backend forwarder
  MUST insert a literal `auth/` segment before the forwarded path, mapping
  1:1 onto the backend's Hydra OIDC routes.
- **path-segments-joined-and-appended**: The backend forwarder MUST join the
  path's segments with `/` and append the result after the resolved prefix
  segment to form the backend target path.
- **query-string-forwarded**: The backend forwarder MUST append the inbound
  request URL's query string (the `?...` suffix, including none when
  absent) to the backend target URL unchanged.
- **host-header-removed**: The backend forwarder MUST remove the `host`
  header from the copied header collection before forwarding, so the
  outbound request carries the backend's own host rather than the inbound
  one.
- **content-length-header-removed**: The backend forwarder MUST remove the
  `content-length` header from the copied header collection before
  forwarding, so the outbound length is recomputed for the outbound body.
- **accept-encoding-forced-identity**: The backend forwarder MUST set the
  outbound `accept-encoding` header to `identity`, overriding whatever the
  inbound request declared, because the runtime's HTTP client transparently
  decodes a gzip/deflate response body while leaving the upstream
  `content-encoding` header in place, and this module returns that response
  verbatim.
- **redirect-not-followed**: The backend forwarder MUST issue the outbound
  request with automatic redirect-following disabled, so a 3xx response and
  its `Set-Cookie` header reach the caller unfollowed and unmodified.
- **body-forwarded-for-mutating-methods**: For any request method other than
  `GET` or `HEAD`, the backend forwarder MUST read the inbound body as a
  raw byte buffer and set it as the outbound body verbatim.
- **no-body-for-get-or-head**: For `GET` or `HEAD` requests, the backend
  forwarder MUST NOT set an outbound body.
- **response-returned-verbatim**: The backend forwarder MUST return the
  response the outbound request resolves with, unmodified — its status,
  headers, and body all pass through exactly as the backend produced them.
- **five-methods-generated**: The handler factory MUST return an object with
  exactly the keys `GET`, `POST`, `PUT`, `PATCH`, and `DELETE`.
- **identical-behavior-across-methods**: Every handler the handler factory
  returns MUST resolve the route's path parameters and call the backend
  forwarder with the same bound prefix, applying identical
  target-resolution, header, and body rules regardless of which of the five
  methods was invoked.
- **params-awaited-before-forwarding**: Each generated handler MUST await
  the route's path parameters before calling the backend forwarder, because
  the host supplies those parameters as a deferred (asynchronous) value.

### Security

This module transits authentication material end to end without inspecting
it. It never parses a cookie, decodes a bearer token, or checks an expiry —
every authentication decision belongs to the backend, and this module's only
job is to relay the backend's decision unchanged.

- **credentials-forwarded-opaquely**: The backend forwarder MUST forward the
  inbound `Cookie` and `Authorization` headers, and every other header not
  explicitly removed, to the backend unmodified, and MUST NOT inspect,
  decode, or log their contents. Traced: the only two header removals in
  source target `host` and `content-length`; nothing in the file reads a
  `Cookie` or `Authorization` value.
- **backend-is-sole-authenticator**: This module MUST NOT itself accept,
  reject, or otherwise adjudicate a caller's credentials; it MUST return
  whatever status the backend responds with — including `401`/`403` — via
  response-returned-verbatim, unchanged. Traced: no status-code branch
  exists anywhere in the backend forwarder.
- **no-token-lifetime-authority**: This module MUST NOT set, extend, or
  revoke any token or session lifetime. Token issuance and expiry belong to
  the backend; storage and refresh belong to sibling modules in this
  package, none of which are part of this recipe's source. Traced: no
  variable in this module holds a token value, and the file imports nothing
  from those sibling modules.

