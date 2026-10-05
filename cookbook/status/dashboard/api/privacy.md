
- **Data collected**: the peer-fleet client's `token` field (a fleet shared
  secret) is the one sensitive value the given sources handle; the
  monitoring-configuration client and the API client carry only
  operational/infrastructure configuration (site, group, and endpoint
  records), never end-user personal data.
- **Storage**: none of these clients persists any value locally; every read
  returns a fresh network response, and nothing is cached or written to
  disk or local browser storage by this module.
- **Transmission**: the peer-fleet client sends `token` as a JSON
  request-body field (via create/update peer), never in a URL or query
  string. The transport scheme is whatever the base path resolves through —
  ordinarily a same-origin path, so secure transport is inherited from the
  hosting page rather than enforced by these clients themselves.
- **Retention**: none — a call's `token` value is not retained by these
  clients beyond the single outbound request; `hasToken` is the only signal
  a subsequent read returns, per peer-view-redaction.

