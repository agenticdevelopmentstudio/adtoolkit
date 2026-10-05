
`packages/web/packages/status-web/src/lib/live-types.ts` declares the `/api/live` contract: in its header's words, "one self-contained snapshot of everything the client displays, pulled live from providers + HTTP probes. Type-only module (shared by the route and the client store); no DB imports."

It exports one string union (`ProviderKey`) and five interfaces (`LiveServiceDTO`, `StaleProdDTO`, `ProviderHealth`, `LiveSnapshot`) built on `ServiceStatusDTO` and `DeploymentDTO` from `../types`. It emits no runtime code.

Consumers in the web package: `use-live-snapshot.ts` types every SSE frame and every `/api/live` poll response as `LiveSnapshot` and compares frames with `isSameSnapshot`; `stale-monitors.ts` selects retire candidates from `LiveServiceDTO[]` using `downSince` and `dnsOk`; `SnapshotStaleBanner` compares `lastCycleAt` against `generatedAt` scaled by `probeIntervalMs`; `Dashboard`, `DetailPanel` and `DeployList` forward `probeIntervalMs`; `OverviewTab` shows `monitorVersion`. `live-snapshot.fixture.ts` builds the default test snapshot. The status server holds its own copy of these types in `status-server/src/monitor/live-types.ts` and produces the payload in `routes/reads.ts`.

