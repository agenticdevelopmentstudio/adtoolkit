
- **Data collected**: The signed-in account's `email`, optional `displayName` and `role`, as returned by `/auth/me`.
- **Storage**: Held only in memory in the shared cache under the key `status-auth-me`. It is never written to local storage, session storage or cookies by this code. The session credential is the httpOnly `status_auth` cookie, which client script cannot read.
- **Transmission**: One same-origin `GET /auth/me` (through the host's `/api` proxy by default). The browser attaches the session cookie, and the client adds no credential of its own.
- **Retention**: For the life of the page's shared cache. A full page load, such as the logout redirect to `/`, discards it. Cookie lifetime and revocation are owned by the status backend.

