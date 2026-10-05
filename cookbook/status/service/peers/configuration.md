
| Option | Type | Default | Description |
|---|---|---|---|
| `peer.baseUrl` | `string` (`PeerRow` field, external — from `storage.peers.listActive()`) | set via `createPeer`/`updatePeer` (external) | The peer's canonical base URL; `fetchPeers` appends `/snapshot` to it. |
| `peer.token` | `string \| null` (`PeerRow` field) | `null` | Bearer credential sent to the peer; when absent, `fetchPeers` sends no `Authorization` header. |
| `peer.isActive` | `boolean` (`PeerRow` field) | `true` (the `peers` table's DB default; the CRUD path is external) | Gates both `fetchPeers`'s poll roster and `assembleFleet`'s member roster — both read from the same `listActive()` call. |
| poll timeout | `number` literal in `fetch.ts` | `10_000` | Not exported, not caller-configurable; the `AbortSignal.timeout` budget for one peer's `/snapshot` request. |
| `config.publicBaseUrl` | `string` (`StatusConfig` field) | `""` | The self-detection input to `isSelfPeerUrl`; empty means "unknown," so no URL is ever flagged as self. |
| `fetchImpl` | `typeof fetch` (optional `fetchPeers` parameter) | global `fetch` | Substitutable for tests; production callers never pass this argument. |
| `self` argument | `{ label: string; snapshot: unknown; overall: string \| null }` (`assembleFleet` parameter) | caller-supplied, no default | This monitor's own compact status, provided by the caller (`routes/fleet.ts`, external) on every call. |

