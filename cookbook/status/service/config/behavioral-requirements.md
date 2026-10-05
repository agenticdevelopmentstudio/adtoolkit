
### Configuration Contract (port.ts)

- **credential-name-list**: `STATUS_CREDENTIAL_NAMES` MUST be exactly the
  twelve literal names `VERCEL_API_TOKEN`, `VERCEL_TEAM_ID`,
  `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `RAILWAY_API_TOKEN`,
  `CRUNCHY_API_TOKEN`, `GLITCHTIP_URL`, `GLITCHTIP_API_TOKEN`,
  `GLITCHTIP_ORG`, `POSTHOG_HOST`, `POSTHOG_API_KEY`, `POSTHOG_PROJECT_ID`,
  in that order, per the `as const` array; `StatusCredentialName` MUST be
  exactly the union of those twelve literals.
- **credential-record-completeness**: `StatusConfig.credentials` MUST carry
  one entry for every name in `STATUS_CREDENTIAL_NAMES`, each either a
  `string` or `undefined`; it MUST NOT omit an unset name from the record's
  keys.
- **config-fields-are-plain-data**: Every field a `StatusConfig` exposes
  MUST be data (a primitive, an array, or a nested plain object), never a
  function, per the interface's own doc comment ("a method does not survive
  it").
- **config-survives-structured-clone**: A `StatusConfig` MUST retain every
  key and an equal `credentials` record after `structuredClone`, since the
  host hands the same object to the monitor worker as `workerData`.
- **secrets-field-identity**: `StatusConfig.secrets` MUST be capable of
  resolving any environment-variable name the host passes it, not only the
  twelve in `STATUS_CREDENTIAL_NAMES`, because a `deploy_integrations` row
  stores the name of its own token in `tokenEnvVar` and that name is
  resolved through `secrets`, external to these three files.
- **deploy-sync-interval-floor**: `deploySyncIntervalMs(config, probeIntervalMs)`
  MUST return `Math.max(300_000, probeIntervalMs * 5)` when
  `config.deploySyncSeconds` is `null`.
- **deploy-sync-interval-override**: `deploySyncIntervalMs` MUST return
  `config.deploySyncSeconds * 1000` when `config.deploySyncSeconds` is not
  `null` and satisfies `Number.isFinite(n) && n > 0`.
- **glitchtip-all-or-nothing**: `glitchtipConfigured(config)` MUST return
  `true` only when `config.credentials.GLITCHTIP_URL`,
  `GLITCHTIP_API_TOKEN`, and `GLITCHTIP_ORG` are all truthy; two of three
  present MUST resolve `false`, per the function's own doc comment ("All
  three or nothing").
- **posthog-all-or-nothing**: `posthogConfigured(config)` MUST return `true`
  only when `config.credentials.POSTHOG_HOST`, `POSTHOG_API_KEY`, and
  `POSTHOG_PROJECT_ID` are all truthy, following the identical shape.

### Environment Adapter (env.ts)

- **production-escape-hatch-guard**: `envConfig(env)` MUST throw an `Error`
  whose message contains `AUTH_DISABLED / COOKIE_INSECURE` when
  `env.NODE_ENV === "production"` and either `env.AUTH_DISABLED === "1"` or
  `env.COOKIE_INSECURE === "1"`, before constructing any `StatusConfig`
  field (SEC-M5).
- **production-escape-hatch-scoped-outside-production**: `envConfig(env)`
  MUST NOT throw for the same `AUTH_DISABLED`/`COOKIE_INSECURE` values when
  `env.NODE_ENV` is not exactly the literal string `"production"`.
- **port-default**: `port` MUST be `3000` when `env.PORT` is unset.
- **app-version-default**: `appVersion` MUST be the literal string
  `"0.0.0"` when `env.APP_VERSION` is unset.
- **git-commit-sha-optional**: `gitCommitSha` MUST be `null` when
  `env.RAILWAY_GIT_COMMIT_SHA` is unset or empty, else the raw string value.
- **probe-interval-default**: `probeIntervalSeconds` MUST be `60` when
  `env.PROBE_INTERVAL_SECONDS` is unset.
- **numeric-env-coercion**: `port` and `probeIntervalSeconds` MUST be
  computed as `Number(env.X ?? default)` with no further check, so any
  numeric string (including `"0"` or a negative value) passes through as
  its `Number()` result and a non-numeric string produces `NaN`; this MUST
  NOT be confused with `deploySyncSeconds` and `github.fetchTimeoutMs`,
  which instead require `Number.isFinite(n) && n > 0` via `positiveNumber`.
- **numeric-env-validation**: The port and probe interval getters MUST return the numeric conversion of their environment values as given. A NaN or non-positive result is accepted with no fallback, no thrown error and no distinguishable signal, unlike the deploy-sync and fetch-timeout getters, which apply a positive-number guard.
- **deploy-sync-seconds-validated**: `deploySyncSeconds` MUST be `null`
  unless `env.DEPLOY_SYNC_SECONDS` parses via `Number()` to a value
  satisfying `Number.isFinite(n) && n > 0`; a blank, zero, negative, or
  non-numeric value MUST resolve `null`, not throw and not clamp.
- **cors-allowed-hosts-parsing**: `corsAllowedHosts` MUST be the
  comma-split, individually trimmed, non-empty entries of
  `env.CORS_ALLOWED_HOSTS`, and `[]` when it is unset.
- **mcp-allowed-hosts-parsing**: `mcpAllowedHosts` MUST follow the identical
  comma-split/trim/non-empty shape over `env.MCP_ALLOWED_HOSTS`.
- **peer-token-default-empty**: `peerToken` MUST be the empty string `""`
  when `env.PEER_TOKEN` is unset.
- **monitor-label-default**: `monitorLabel` MUST resolve its base label to
  the literal string `"this monitor"` when `env.MONITOR_LABEL` is unset or
  blank, before any environment qualification is applied.
- **monitor-label-production-unqualified**: `monitorLabel` MUST NOT append
  an environment suffix when `env.RAILWAY_ENVIRONMENT_NAME` is unset or is
  exactly `"production"` (case-insensitive after trimming).
- **monitor-label-qualified-non-production**: `monitorLabel` MUST append
  `` (<env>) `` (lower-cased, trimmed) to the base label when
  `env.RAILWAY_ENVIRONMENT_NAME` is set to any other non-empty value.
- **monitor-label-no-double-qualification**: `monitorLabel` MUST NOT append
  the suffix when the base label already contains the lower-cased
  environment name as a substring.
- **auth-disabled-flag**: `authDisabled` MUST be `true` if and only if
  `env.AUTH_DISABLED` is exactly the string `"1"`.
- **cookie-secure-flag**: `cookieSecure` MUST be `true` unless
  `env.COOKIE_INSECURE` is exactly the string `"1"`, in which case it MUST
  be `false`.
- **admin-emails-lowercased**: `adminEmails` MUST be the comma-split,
  trimmed, lower-cased, non-empty entries of `env.ADMIN_EMAILS`.
- **public-base-url-fallback**: `publicBaseUrl` MUST prefer
  `env.PUBLIC_BASE_URL` when it is truthy, else derive
  `` https://${env.RAILWAY_PUBLIC_DOMAIN} `` when that is set, else resolve
  the empty string.
- **public-base-url-trailing-slash-strip**: `publicBaseUrl` MUST strip
  exactly one trailing `/` via `raw.replace(/\/$/, "")`; a value ending in
  two or more slashes MUST retain every slash but the last one, since the
  pattern is not global and matches at most once.
- **github-config-shape**: `github.clientId` and `github.clientSecret` MUST
  each default to the empty string when their respective
  `GITHUB_OAUTH_CLIENT_ID`/`GITHUB_OAUTH_CLIENT_SECRET` env vars are unset;
  `github.fetchTimeoutMs` MUST be `null` unless
  `env.GITHUB_FETCH_TIMEOUT_MS` parses via `positiveNumber` to a finite
  value greater than zero.
- **webhook-secrets-optional**: `webhooks.vercel` and `webhooks.railway`
  MUST each independently be `null` unless their respective
  `VERCEL_WEBHOOK_SECRET`/`RAILWAY_WEBHOOK_SECRET` env var is a non-empty
  string, in which case they MUST be that string.
- **heartbeat-alert-urls-optional**: `heartbeatUrl` and `alertWebhookUrl`
  MUST each independently be `null` unless their respective
  `HEARTBEAT_URL`/`ALERT_WEBHOOK_URL` env var is a non-empty string.
- **glitchtip-projects-default-null**: `glitchtipProjects` MUST be `null`
  when `env.GLITCHTIP_PROJECTS` is unset or blank after trimming, meaning
  every project the org returns.
- **glitchtip-projects-parsing**: `glitchtipProjects` MUST be the
  comma-split, trimmed, non-empty entries of a non-blank
  `env.GLITCHTIP_PROJECTS`, and MUST resolve `null` (not `[]`) when that
  split yields zero entries, so a value of `",,"` is treated the same as
  unset rather than as an empty allowlist.
- **credentials-mapping**: `credentials[name]` MUST equal
  `env[name]` for every `name` in `STATUS_CREDENTIAL_NAMES`, `undefined`
  passed through as `undefined`, never defaulted to a string.
- **secrets-full-passthrough**: `secrets` MUST expose every key present on
  the `env` object handed to `envConfig`, including a name outside
  `STATUS_CREDENTIAL_NAMES` (e.g. a per-integration `tokenEnvVar` such as
  `STATUS_TEST_VERCEL_TOKEN`).
- **lazy-field-evaluation**: Every `StatusConfig` field `envConfig` returns
  MUST be implemented as a getter that reads `env` at the moment of
  property access, not at the moment `envConfig(env)` is called, so a
  caller that mutates the same `env` object after construction MUST see the
  new value on the next read, per the function's own doc comment.
- **production-guard-environment-signal**: the SEC-M5 guard inspects only `env.NODE_ENV === "production"`, never `env.RAILWAY_ENVIRONMENT_NAME` (the signal `monitorLabel` reads to detect a non-production Railway environment), so a deployment whose `NODE_ENV` is not the exact literal `"production"` boots with `AUTH_DISABLED`/`COOKIE_INSECURE` honored. Setting `NODE_ENV` correctly is owned by the service's Railway deployment configuration.

### Seed Roster Contract (seed.ts)

- **seed-environment-enum**: `SeedEnvironment` MUST be exactly the union
  `'production' | 'staging' | 'testing'`.
- **seed-endpoint-required-fields**: A `SeedEndpoint` value MUST supply
  `group`, `name`, `baseSlug`, `host`, `envs`, and `kind`; the interface
  declares none of these optional.
- **seed-endpoint-optional-fields-default**: A `SeedEndpoint`'s `path` and
  `expectedStatus` fields MUST be optional (`path?: string`,
  `expectedStatus?: number`); the type itself carries no default value for
  either — the `200` default documented on `expectedStatus` is applied by
  the external seed-route consumer, not by this type.
- **seed-endpoint-name-uniqueness-precondition**: A `SeedEndpoint`'s `name`
  MUST be unique within its `group`, per the field's own doc comment ("The
  site's display name, unique within its group"); this is a documented
  caller precondition these three files declare but do not themselves
  enforce at runtime.
- **seed-roster-shape**: `SeedRoster` MUST be `readonly SeedEndpoint[]`, a
  read-only list, never a mutable array or a keyed map.
- **seed-roster-empty-semantics**: An omitted or empty `SeedRoster` MUST
  correspond to the seed route creating no groups, sites, or endpoints —
  only the provider connections whose credentials are already present —
  per this file's own module doc comment and `app.ts`'s `AppDeps.seed` doc
  comment.
- **seed-fan-out-contract**: Per `SeedEndpoint`'s own doc comment (enforced
  by the external seed-route consumer, `runSeed` in `src/routes/config.ts`),
  one `SeedEndpoint` row MUST fan out into exactly one site-group keyed by
  `group`, one site keyed by the pair `(group, name)` with slug `baseSlug`,
  and one endpoint for every entry in `envs`.
- **seed-endpoint-url-construction**: Each fanned-out endpoint's URL MUST
  be `` https://<env-qualified host><path ?? ''> ``, where the production
  entry in `envs` leaves `host` unqualified and the staging/testing entries
  prefix it `staging.`/`testing.`, per `SeedEndpoint`'s doc comment ("The
  non-production hosts follow the `staging.<host>` / `testing.<host>`
  convention").
- **seed-plain-data**: `SeedEndpoint` and `SeedRoster` MUST hold no
  functions, matching `StatusConfig`'s "plain data, like StatusConfig" doc
  comment, so a host can keep a seed roster in a JSON file.

### Security

This module is where every credential and CORS/MCP origin allowlist the
status backend trusts is named and surfaced — twelve provider tokens by
name (`STATUS_CREDENTIAL_NAMES`), the machine `PEER_TOKEN`, the GitHub OAuth
`clientSecret`, two inbound webhook secrets, and the explicit host lists the
external CORS and MCP middleware consult. It is a security-relevant recipe
per this cookbook's Cookbook Compliance guideline, so the concerns below are
addressed explicitly.

- **credential-values-opaque**: None of `env.ts`, `port.ts`, or `seed.ts`
  MUST decode, parse, or validate the semantic content of a credential
  string; every credential and secret field is a `string | undefined`
  passthrough, meaningful only to the external code that presents it to a
  provider API.
- **cors-hosts-explicit-list-only**: `corsAllowedHosts` and
  `mcpAllowedHosts` MUST be a finite, explicit array of host names; neither
  the `EnvSource` type nor the `list()` helper produces or accepts a
  wildcard sentinel, so a wildcard-CORS decision, if ever made, happens
  entirely in the external middleware that reads this array, not in these
  three files.
- **peer-token-empty-disables-peer-path**: `peerToken` defaulting to `""`
  MUST leave the peer-authenticated read path disabled by construction, per
  `StatusConfig.peerToken`'s own doc comment ("Empty disables peer reads");
  the comparison logic that enforces this lives in `status-server-auth`'s
  `default-adapter.ts`, external to these three files.

Sensitive data in scope: the twelve `STATUS_CREDENTIAL_NAMES` provider
tokens, `PEER_TOKEN`, `github.clientSecret`, `webhooks.vercel`/`.railway`,
and every other environment-variable value reachable through `secrets`.
None of these three files stores, logs, or transmits any of them — they are
read from `env` and handed to the caller by reference. Storage (the host's
own environment/secrets manager, e.g. Railway's env store), transmission
(each credential's own provider-API call, made by code outside this
recipe), and revocation (rotating the underlying provider token) are all
external to `env.ts`, `port.ts`, and `seed.ts`; what these three files
guarantee is that a credential's value is never inspected, mutated, or
duplicated on its way from `env` to `credentials`/`secrets`.

