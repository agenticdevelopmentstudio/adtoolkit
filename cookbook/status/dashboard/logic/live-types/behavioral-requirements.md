
### Module shape

- **type-only-module**: The module MUST export only types; importing it MUST produce no runtime value or side effect.
- **no-db-imports**: The module MUST NOT import database or storage code; its only import MUST be the type-only import of `ServiceStatusDTO` and `DeploymentDTO` from `../types`.
- **no-runtime-validation**: The module MUST NOT validate a payload at runtime; `use-live-snapshot.ts` casts `JSON.parse(data) as LiveSnapshot` and `(await r.json()) as LiveSnapshot` unchecked, so a mismatched payload reaches consumers as-is.
- **server-parity**: The header comment says the module is "shared by the route and the client store", but the text is duplicated verbatim in a separate server copy (`status-server/src/monitor/live-types.ts`), and that copy is what the route uses. No parity test pins the two copies, unlike `board-types-parity.test.ts` and `deploy-status-parity.test.ts`, so a field changed in only one copy still compiles in both packages. A port keeps one definition of these types for both server and client, or adds a parity test.

### LiveServiceDTO

- **live-service-extends**: `LiveServiceDTO` MUST carry every field of `ServiceStatusDTO` (`slug`, `group`, `name`, `url`, `environment`, `platform`, `deployProject`, `status`, `responseTimeMs`, `statusCode`, `error`, `lastCheckedAt`) plus `dnsOk` and `downSince`.
- **live-service-status-values**: `LiveServiceDTO.status` MUST be one of `"healthy"`, `"degraded"`, `"down"` or `"unknown"` (`HealthStatus | "unknown"`).
- **dns-ok-field**: `dnsOk` MUST be a required `boolean` stating whether the hostname resolved in DNS.
- **dns-ok-source-meaning**: `dnsOk: false` MUST denote a `dns`-source problem, not an `http`-source one.
- **down-since-field**: `downSince` MUST be a required `string | null`: the ISO time the endpoint's current http/dns issue opened.
- **down-since-null**: `downSince` MUST be `null` when the endpoint is not down.
- **down-since-server-truth**: `downSince` MUST be the server's durable onset, identical across browsers, and consumers MUST NOT substitute a per-tab onset for it.

### StaleProdDTO

- **stale-prod-fields**: `StaleProdDTO` MUST carry exactly `projectName: string`, `environment: string`, `detail: string | null`, `sourceUrl: string | null`, `liveUrl: string | null`.
- **stale-prod-prefiltered**: Every entry in `LiveSnapshot.staleProd` MUST already be a Vercel project whose live production deploy is errored or behind; consumers MUST NOT re-filter it for staleness.

### Providers

- **provider-key-members**: `ProviderKey` MUST be exactly `"vercel" | "cloudflare-pages" | "railway" | "crunchy"`.
- **provider-health-fields**: `ProviderHealth` MUST carry exactly `configured: boolean` and `ok: boolean`.
- **provider-configured-meaning**: `configured` MUST be `true` only when the platform is actually polled: an active integration that has a token.
- **provider-ok-meaning**: `ok` MUST state whether the latest poll reached the provider API.
- **providers-complete**: `LiveSnapshot.providers` MUST be a `Record<ProviderKey, ProviderHealth>` holding an entry for every one of the four `ProviderKey` members.

### LiveSnapshot

- **snapshot-required-fields**: `LiveSnapshot` MUST carry the required fields `generatedAt: string`, `services: LiveServiceDTO[]`, `deployments: DeploymentDTO[]`, `staleProd: StaleProdDTO[]`, `providers: Record<ProviderKey, ProviderHealth>`, `configDegraded: boolean`, `configReason: string | null`.
- **snapshot-optional-fields**: `LiveSnapshot` MUST declare `lastCycleAt?: string | null`, `probeIntervalMs?: number` and `monitorVersion?: string | null` as optional, so a payload from an older backend that omits them still typechecks.
- **generated-at-meaning**: `generatedAt` MUST be an ISO timestamp from the server clock, stamped at read time, and MUST serve as the client's event-time reference.
- **generated-at-identity**: `generatedAt` MUST identify a delivery: two snapshots with equal `generatedAt` are the same frame (`isSameSnapshot` returns `true` for them).
- **last-cycle-at-meaning**: `lastCycleAt` MUST be the ISO time of the newest persisted probe, and `null` before the first probe.
- **last-cycle-at-distinct**: `lastCycleAt` MUST NOT be treated as the scheduler's cycle-completion clock served at `/health`.
- **last-cycle-at-absent**: An absent or `null` `lastCycleAt` MUST yield no staleness warning; `snapshotFreshness` returns `"fresh"` and `SnapshotStaleBanner` renders nothing.
- **probe-interval-meaning**: `probeIntervalMs` MUST be the backend's probe interval in milliseconds, so the client's staleness window scales with it.
- **probe-interval-absent**: An absent `probeIntervalMs` MUST fall back to the client's floor; `snapshotStaleMs` returns `max(probeIntervalMs * 5, 300000)`, which is 300000 ms when the field is missing.
- **monitor-version-meaning**: `monitorVersion` MUST be the git commit the monitor itself is running, or `null` when there is none (locally).
- **monitor-version-absent**: An absent or `null` `monitorVersion` MUST cause the board to show no version.
- **config-degraded-meaning**: `configDegraded` MUST be `true` only when the server's config read fell back to the static list because the database was unreachable.
- **config-reason-field**: `configReason` MUST be a `string | null` carried beside `configDegraded`; the module gives no further meaning to it.

### Concurrency and side effects

- **no-side-effects**: The module MUST perform no I/O, hold no state and have no ordering or concurrency behavior; it is erased at compile time.

