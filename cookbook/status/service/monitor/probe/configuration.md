
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `opts.timeoutMs` | `number` | `HEALTH_CHECK_TIMEOUT_MS` (`10_000`, from `health.ts`) | Deadline, in milliseconds, for the whole HTTP leg of one `probe` call — headers and any body read. |
| `opts.dnsTimeoutMs` | `number` | `DNS_TIMEOUT_MS` (`5_000`, private to this file — not exported) | Deadline, in milliseconds, for the DNS-resolution step of one `probe` call. |
| `svc.url` | `string` | none — required | The endpoint URL `probe` issues its `GET` request against, and the source `new URL(...)` parses for the DNS-resolution hostname. |
| `svc.kind` | `string` | none — required | When exactly `"health"`, gates the JSON-body status check inside `classify` and forces a capped body read even without `expectBody` set. |
| `svc.expectedStatus` | `number` | none — required | The status code `classify` treats as acceptable even when it is not itself a 2xx response. |
| `svc.expectBody` | `string \| null \| undefined` | `null`/`undefined` (no marker check) | An optional content marker; when set, `probe` reads and searches the capped body for this substring. |
| `svc.dnsCheckA` / `svc.dnsCheckAaaa` / `svc.dnsCheckCname` | `boolean \| undefined` | `true` (via `??`) for each | Per-endpoint toggles for which DNS record types `resolveDns` queries; all three `false` skips the DNS step entirely. |
| `HEALTH_PROBE_CONCURRENCY` (exported module constant) | `number` | `24` | The concurrency limit `probeEndpoints` passes to `mapLimit`; not overridable by a caller of `probeEndpoints`. |
| `PROBE_BODY_MAX_BYTES` (exported module constant) | `number` | `262144` (`256 * 1024`) | The byte cap `probe` passes to every capped body read it performs; not overridable by a caller of `probe`. |

