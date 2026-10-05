
- **Data collected**: this module originates no data of its own; it reads and writes role,
  grant, and assignment records identifying which subjects (`customer`/`persona`/`team`)
  hold which roles at which scopes. These are access-control records, not end-user PII.
- **Storage**: none. The client is a stateless per-call request builder; it holds nothing in
  memory or on disk beyond the lifetime of a single call, per `no-client-side-cache` and
  `stateless-module`.
- **Transmission**: yes. Every call carries a bearer credential attached by the shared
  authentication client (`auth-delegated-to-shared-client`), not by this module; whatever
  transport security the deployment provides is outside the scope of these two files.
- **Retention**: none. Nothing this module handles is retained after the response it
  produced is returned to the caller.

