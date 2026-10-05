
- **Data collected**: this module originates no data of its own; it reads and writes monitoring
  configuration records — group/site names and slugs, retention windows, and endpoint URLs, kinds, and
  check intervals. These are infrastructure-monitoring configuration records, not end-user PII.
- **Storage**: none. Every operation is a stateless per-call request builder (`no-client-side-cache`,
  `module-holds-no-mutable-state`); nothing is held in memory or on disk beyond the lifetime of a single
  call.
- **Transmission**: yes. Every call carries a bearer credential attached by the shared authenticated
  request client, not by this module; whatever transport security the deployment provides is outside
  the scope of this recipe.
- **Retention**: none. Nothing this module handles is retained after the response it produced is
  returned to the caller.

