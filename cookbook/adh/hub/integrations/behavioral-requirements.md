
**Provider catalog**

- **provider-catalog-fetch**: Listing providers MUST send `GET {BASE}/providers`, where `BASE` is
  the fixed constant `/api/integrations`, and MUST return the providers array unwrapped from the
  `{ providers }` response envelope.

**Provider configs — provider-id-addressed**

- **provider-config-list**: Listing provider configs MUST send `GET {BASE}/ecosystems/<enc(ecosystemId)>/provider-configs`
  and MUST return the configs array unwrapped from `{ configs }`.
- **provider-config-get-by-provider-id**: Getting a provider config by provider id MUST send `GET {BASE}/ecosystems/<enc(ecosystemId)>/provider-configs/<enc(providerId)>`.
- **provider-config-get-not-found-null**: Getting a provider config by provider id MUST return `null`, not throw, when that
  request fails with a not-found response (a backend `404`); any other thrown error MUST propagate unchanged.
- **provider-config-put-preserves-blank-secret**: Saving a provider config by provider id MUST send `PUT` to that same
  path with the given provider-config input JSON-serialized verbatim as the body; per that input's own `clientSecret`
  field's documented contract, a blank or absent `clientSecret` in that body MUST preserve the config's currently stored
  secret rather than clearing it.
- **provider-config-delete-by-provider-id**: Deleting a provider config by provider id MUST send `DELETE` to that same
  path and MUST resolve with no value.

**Provider configs — id/rdid-addressed**

- **provider-config-create**: Creating a provider config MUST send `POST {BASE}/ecosystems/<enc(ecosystemId)>/provider-configs`
  (the collection path, with no trailing id segment) with a body naming the provider id, a name, and the same input
  fields as saving-by-provider-id, JSON-serialized verbatim, and MUST return the resulting provider config record.
- **provider-config-get-by-id**: Getting a provider config by id MUST send `GET {BASE}/ecosystems/<enc(ecosystemId)>/provider-configs/<enc(configId)>`.
- **provider-config-get-by-id-not-found-null**: Getting a provider config by id MUST return `null`, not throw, on a
  not-found response, matching provider-config-get-not-found-null's pattern for the provider-id-addressed lookup.
- **provider-config-update-by-id**: Updating a provider config by id MUST send `PUT` to that same id-addressed path with
  a provider-config input body optionally extended with a `name`.
- **provider-config-delete-by-id**: Deleting a provider config by id MUST send `DELETE` to that same id-addressed path
  and MUST resolve with no value.
- **provider-config-two-address-schemes-share-a-url-shape**: the provider-id-addressed path (built by a private
  path-building helper given a provider id) and the id/rdid-addressed path (built by a second private path-building
  helper) MUST both resolve to the identical template `{BASE}/ecosystems/<enc(ecosystemId)>/provider-configs/<enc(...)>`
  — the two helpers differ only in the name of the parameter they encode into the trailing segment, never in the URL
  shape produced (see Design Decisions).

**Credential testing**

- **test-saved-config**: Testing a saved provider config MUST send `POST` to the id-addressed config path's `/test`
  sub-path and MUST return a test-result record.
- **test-saved-config-github-app-also-connects**: for a `github_app` provider, testing a saved provider config IS the
  connect: the only proof an app id and private key are real is minting a JWT and enumerating the installations the
  app can see, and that enumeration itself creates the connection rows and warms the repository cache. The test
  result's `adopted` field, when present, MUST report the outcome of that side effect (connected/skipped
  installations), and a caller holding a connection list MUST refresh it whenever `adopted` is present.
- **test-result-ok-false-is-not-an-error**: a refused credential MUST resolve either testing operation with `{ ok:
  false, summary, notes }`, never throw; only a malformed request (an unknown provider, a field the provider does not
  declare, or a provider with no way to be tested at all) MUST throw.
- **test-draft-credentials-writes-nothing**: Testing draft credentials MUST send `POST {BASE}/providers/<enc(providerId)>/test-credentials`
  with the given credentials body, and MUST NOT create or modify a provider config, a connection, or a repository
  cache — the whole difference from testing a saved config.
- **test-draft-credentials-with-stored-secret**: when the credentials body's `providerConfigId` is given with a blank
  `clientSecret`, testing draft credentials MUST test against that config's already-stored secret rather than an empty
  one, because a saved secret is never re-displayed in an edit form (it is write-only): a blank field there means
  "unchanged," not "no secret."

**Transfer**

- **transfer-request-shape**: Transferring a provider config MUST send `POST` to the id-addressed config path's
  `/transfer` sub-path with a body naming a `targetEcosystemId` and MUST return a transfer-result record.
- **transfer-moves-credential-connections-and-caches-together**: the result MUST report the moved config's credential,
  the connections it minted, and their cached repository lists as having moved together in one result; the caller
  MUST manage both the source and destination ecosystem after a transfer.
- **transfer-mints-new-rdid**: the transferred config's `rdid` MUST be treated as re-minted at the destination
  ecosystem; the address it answered to before the transfer MUST NOT be assumed to still resolve.
- **transfer-connections-count-is-live-only**: the transfer result's connection count MUST count only connections that
  are live at the destination, not the number of connection rows that were moved; a moved connection that was already
  disconnected MUST NOT be counted.

**Webhook secret rotation**

- **rotate-webhook-secret-request-shape**: Rotating a webhook secret MUST send `POST` to the id-addressed config
  path's `/rotate-webhook-secret` sub-path with no body and MUST return the updated provider config record.
- **rotate-webhook-secret-is-destructive**: the newly minted secret MUST invalidate the previously stored one
  immediately; per the source's own comment, a provider still configured with the old secret is expected to start
  failing its own delivery attempts at the provider's side with no signal raised by this client.
- **rotate-webhook-secret-also-generates-first-secret**: for a provider config record whose deliverability-webhook
  secret is `null` (a config created before per-config secrets existed), rotating the webhook secret MUST be the only
  operation in this client that gives that config a working secret.

**Connections**

- **connections-list-scoped-by-ecosystem**: Listing connections MUST send `GET {BASE}?ecosystemId=<enc(ecosystemId)>`
  and MUST return the connections array unwrapped from `{ connections }`, across every provider owned by that
  ecosystem.
- **connect-request-shape**: Connecting MUST send `POST {BASE}/connect` with the given connect-request body
  JSON-serialized verbatim and MUST return the resulting connection record.
- **connect-every-variant-names-ecosystem**: every member of the connect-request body's six auth-method variants
  (`oauth`, `api_key`, `app_password`, `plaid_link`, `oauth_instance`, `github_app`, keyed by `type`) MUST include
  `ecosystemId`; connecting names the target ecosystem in the body on every call regardless of auth method.
- **connect-github-app-has-no-code**: the `github_app` variant MUST carry `installationId` and MUST NOT carry a
  `code` field — unlike every other variant, which exchanges an authorization code, a GitHub App installation is not
  an authorization to exchange; it already exists and is addressed by id.
- **connect-app-password-source-exclusivity-delegated**: the `app_password` variant MAY supply inline credentials
  (`identifier`, `password`, `instanceUrl`) or a `providerConfigId` to source them from a saved ecosystem provider
  config; connecting MUST NOT reject a body that supplies both or neither — per the variant's own documented
  contract, that exclusivity is enforced server-side, not by this client.
- **disconnect-request-shape**: Disconnecting MUST send `DELETE {BASE}/<enc(connectionId)>` and MUST resolve with no
  value; it soft-deletes a connection the caller owns.
- **sync-request-shape**: Syncing a connection MUST send `POST {BASE}/<enc(connectionId)>/sync` and MUST resolve with
  no value on success.
- **sync-no-worker-throws-503**: Syncing a connection MUST throw an error carrying status `503` when no worker is
  registered yet for the connection's provider; per the source's own comment, the caller shows this as an inline "not
  available" note rather than a hard error.
- **patch-settings-request-shape**: Patching a connection's sync settings MUST send `PATCH {BASE}/<enc(connectionId)>/settings`
  with the given settings body and MUST return the result (`{ ok, syncSettings }`) verbatim.

**OAuth / install / instance / link-token start endpoints**

- **auth-url-request-shape**: Getting an OAuth authorization URL MUST send `GET {BASE}/providers/<enc(providerId)>/auth-url`
  with query parameters `ecosystemId` and `redirectUri` always present, and `serviceType`/`scopes` appended only when
  given, and MUST return a result (`{ url, state }`).
- **install-url-request-shape**: Getting an app-install URL MUST send `GET {BASE}/providers/<enc(providerId)>/install-url`
  with query parameter `ecosystemId` always present and `serviceType` appended only when given; it MUST NOT send a
  `redirectUri` or `scopes` parameter — a GitHub App's setup URL is configured on the app at the provider, not
  supplied per request, and its permissions are declared on the app rather than negotiated per call.
- **adopt-installations-request-shape**: Adopting installations MUST send `POST {BASE}/providers/<enc(providerId)>/adopt-installations`
  with the given body and MUST return a result (`{ connected, skipped }`).
- **adopt-installations-requires-config-id**: the adopt-installations body's `providerConfigId` MUST be a required
  field; per the source's own comment, the app's identity MUST be read by that id rather than resolved any other way,
  because a resolver that falls through to a platform-global app would surface installations belonging to other
  tenants.
- **adopt-installations-idempotent**: calling adopt-installations a second time for the same saved config MUST report
  an already-connected installation under `skipped` rather than creating a duplicate connection; the operation MUST
  be safe to call more than once.
- **register-instance-request-shape**: Registering a self-hosted instance MUST send `POST {BASE}/providers/<enc(providerId)>/register-instance`
  with the given body and MUST return a result (`{ state, authorizeUrl, clientId }`).
- **register-instance-config-id-overrides-instance-url**: when the register-instance body's `providerConfigId` is
  set, the per-instance `clientId`/`clientSecret`/`instanceUrl` MUST be sourced from that saved provider config
  instead of a dynamic per-user app registration, even though the body's `instanceUrl` remains a required field and
  is sent — but ignored on this path.
- **create-link-token-request-shape**: Creating a link token MUST send `POST {BASE}/providers/<enc(providerId)>/link-token`
  with the given body, or `{}` when no body is given, and MUST return `{ linkToken }`.

**OAuth callback path and state claims**

- **oauth-callback-path-fixed**: the OAuth callback path MUST be the fixed string `/integrations/oauth-callback`,
  shared by the connect flow that builds a `redirectUri` from it and the callback page that receives the provider's
  redirect, so both agree on the path.
- **oauth-callback-url-is-origin-relative**: building the OAuth callback URL MUST return `<origin><OAuth callback
  path>`; it MUST be called only in a browser context, since it reads the current page's origin with no guard (a
  documented, client-only precondition).
- **decode-state-claims-grammar**: decoding OAuth state claims MUST return `null` for any `state` string that has no
  `.` separator, or whose `.` is the first character, or whose `.` is the last character.
- **decode-state-claims-base64url-json**: decoding OAuth state claims MUST decode only the substring before the `.`
  as base64url-encoded, fatal-UTF-8-decoded JSON, and MUST return `null` when that decode fails or produces a
  non-object value.
- **decode-state-claims-field-validation**: decoding OAuth state claims MUST return `null` unless the decoded
  object's `customerId`, `providerId`, `serviceType`, and `ecosystemId` are all non-empty strings and its `iat` is a
  finite number; when all five checks pass it MUST return claims carrying exactly those five fields.
- **decode-state-claims-never-verifies-signature**: decoding OAuth state claims MUST NOT verify the signature half of
  `state` — per the source's own comment, it exists only to let this client answer questions like the state-freshness
  check locally; every value it recovers MUST still be re-verified by the backend (signature, caller identity,
  ecosystem) before the connect request persists anything, and a forged `state` MUST get the same rejection it would
  have gotten without this function.
- **state-freshness-window**: checking OAuth state freshness MUST return `true` only when `now - claims.iat` is
  between `-(OAUTH_STATE_FUTURE_SKEW_MS + OAUTH_STATE_CLOCK_GRACE_MS)` and `OAUTH_STATE_TTL_MS + OAUTH_STATE_CLOCK_GRACE_MS`
  inclusive, using the current time when the caller does not supply one.
- **state-freshness-constants**: `OAUTH_STATE_TTL_MS` MUST be `600000` (10 minutes), `OAUTH_STATE_FUTURE_SKEW_MS`
  MUST be `60000` (1 minute), and `OAUTH_STATE_CLOCK_GRACE_MS` MUST be `30000` (30 seconds).

**Cross-cutting**

- **every-identifier-url-encoded**: every path-segment identifier this client builds (`ecosystemId`, `providerId`,
  `configId`, `connectionId`) MUST be percent-encoded before being placed in a URL path.
- **no-client-side-cache**: the client MUST NOT cache or memoize any response; every operation issues exactly one
  HTTP request per call.
- **stateless-module**: the client and its standalone exported functions MUST hold no mutable module-level state
  across calls; the only module-level values are the base-path string constant and the three OAuth-state numeric
  constants, all fixed.
- **errors-propagate-except-not-found-lookups**: every client operation MUST let a non-2xx response propagate as a
  thrown error, except getting a provider config by provider id and by id, which MUST catch a `404` specifically and
  resolve `null` instead.

### Security

This is a security-relevant recipe: it manages OAuth authorization flows, ecosystem-scoped provider
credentials (masked OAuth client secrets and GitHub App private keys), and per-config inbound webhook
secrets.

- **secrets-are-write-only**: a provider config's `clientSecret` MUST never be echoed back by any read
  operation in this client — listing provider configs and getting one by provider id or by id all
  return a masked config row whose `hasSecret: boolean` reports only whether a secret is stored, never
  its value.
- **webhook-secret-visibility-after-mint**: the deliverability-webhook secret is typed `string | null`
  (`null` means "no secret is stored yet") and is passed through exactly as the backend returns it on
  every read — listing, getting by provider id, getting by id, and rotating the webhook secret alike.
  Unlike `clientSecret`, which every wire row redacts to `hasSecret: boolean`, this client applies no
  redaction to the webhook secret; whether a later read carries it in cleartext is decided by the
  backend, not by this module.
- **oauth-state-claims-not-authorization**: the OAuth `state` this client decodes carries `customerId`,
  `providerId`, `serviceType`, and `ecosystemId` in cleartext (base64url-encoded, not encrypted) with
  only an HMAC signature for integrity; decoding OAuth state claims' output MUST NOT be used for any
  authorization decision by a caller of this module — per decode-state-claims-never-verifies-signature,
  it informs a pre-flight check only, never a write.
- **ecosystem-scoping-authorized-server-side**: every operation in this client that names an
  `ecosystemId` MUST rely on the backend to authorize the caller against it; this client performs no
  client-side ecosystem-membership check, and per the module's own top-of-file comment a caller
  addressing an ecosystem it does not own MUST receive a thrown error with status `403`, never a silent
  success or crash.
- **rotate-webhook-secret-requires-caller-confirmation**: rotating a webhook secret SHOULD NOT be
  triggered without positive caller confirmation, because the immediate invalidation of the previous
  secret (rotate-webhook-secret-is-destructive) cannot be undone through this client (see Design
  Decisions for why this is a SHOULD, not a MUST, at this layer).
- **session-refresh-waterfall**: a `401` response to any client call MUST trigger exactly one token
  refresh and one retried request, inherited unconditionally from the shared authenticated-request
  mechanism; a second `401` on the retried request MUST propagate as a thrown error with `status: 401`.
  This module defines no refresh or retry logic of its own.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved `401` MUST cause the
  call to throw an error, carrying the response's HTTP status and, when the body supplies one, a
  machine-readable `code`.

