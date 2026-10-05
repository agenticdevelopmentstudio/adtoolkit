
- **Data collected**: the personal API tokens client originates and returns personal API token
  records — `id`, `name`, `prefix` ("non-secret leading chars, for display"), `createdAt`,
  `expiresAt`, `lastUsedAt`, `scope` — and, on minting only, the raw secret `token` value, documented as
  "shown exactly once." The bucket access lists client reads and writes access-group, member, and grant
  records identifying which principals (`user`/`organization`/`persona`/`app`/`token`) hold which CRUD
  grants at which targets. The token secret is credential material; the access-group records are
  access-control records, not end-user PII.
- **Storage**: none within this component. Both clients are stateless per-call request builders (per
  `stateless-module`); neither holds the minted secret, a session token, or any access-control record
  in memory or on disk beyond the lifetime of a single call.
- **Transmission**: yes. Every call carries a bearer session credential attached by the shared
  authenticated-request helper (`auth-delegated-to-shared-client`), not by these clients; minting
  additionally receives a freshly issued raw secret token in its response body. Whatever transport
  security the deployment provides is outside the scope of this component.
- **Retention**: none within this component. Whatever the backend retains — token metadata rows,
  access group/member/grant rows — is outside the scope of these clients.

