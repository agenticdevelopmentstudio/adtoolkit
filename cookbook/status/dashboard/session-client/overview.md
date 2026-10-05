
Two top-level pieces of logic: the session-and-header-auth logic and the wire-types module.

The session-and-header-auth logic is the dashboard's client-side view of the status backend's
**local** session (the `status_auth` httpOnly cookie set by `/api/auth/login`,
not adh SSO). Because the cookie is httpOnly, the client learns the session only
by asking `GET {base}/auth/me`. It exports the session-fetch function (one
request, strict "non-OK is infrastructure trouble, not sign-out" semantics),
the session hook (the one shared cache entry under
the session query key, read by the header seam, the board gate and the
landing page), and the header-auth hook (the injectable auth source a host
passes to its own header component). It declares its own
header-auth state shape so the package carries no dependency on any
site's header package. It is published as its own subpath and
re-exported from the package barrel.

The wire-types module is type-only: the wire DTOs the dashboard reads from the status
backend (the status response, the uptime response, a deployment record,
the history response, the integrations report and their element types). It has no
runtime code and is imported by the package's own components and hooks; it is
not re-exported from the barrel.

