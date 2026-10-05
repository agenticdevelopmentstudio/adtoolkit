
This is the client for the `/api/integrations` surface. It covers three things: the
provider catalog (every provider the platform can integrate, with its auth method and
capabilities); an ecosystem's own, owner-scoped provider configs (OAuth client
credentials or a GitHub App's identity, plus optional endpoint overrides, addressed two
different ways — by a provider id and by the config's own id/rdid); and an ecosystem's
connections (linked accounts) — list, connect (all six connect-request auth methods),
disconnect, sync-now, per-connection sync settings, plus the OAuth/app-install/
self-hosted-instance/Plaid-Link start endpoints and a local, non-authoritative decoder
for the signed OAuth `state` round-trip value. The client exposes twenty
request-building operations plus four standalone OAuth-callback-path and state-claim
helpers, all built on a shared authenticated-request helper and a percent-encoding
helper for path segments. It is a headless **logic** module — no visual surface — so
this recipe marks Appearance, States, and Accessibility not applicable and carries the
runtime contract entirely in Behavioral Requirements, per the non-UI component guidance
this recipe was authored under.

