
- **Data collected**: this file's only externally-supplied input is `svc: ConfiguredEndpoint` (an operator-configured probe target — URL, expected status, optional body marker, DNS-check toggles) and the two optional `ProbeOptions` deadlines; it collects nothing about the requester or any end user.
- **Storage**: none. `probe` and `probeEndpoints` hold no state between calls and write nothing themselves; persisting a `Probe` result is the caller's concern (`sync.ts`, external to this file).
- **Transmission**: `probe` sends one outbound `GET` request, carrying the fixed `User-Agent: AgenticDeveloperHubStatus/1.0` header, to whatever `svc.url` the operator configured, and issues DNS queries against the process's configured resolver for `svc.url`'s hostname. No credential, token, or end-user data is attached to either.
- **Retention**: not applicable — this file holds no data across calls to retain; retention of persisted probe history is `sync.ts`'s concern, external to this file.

