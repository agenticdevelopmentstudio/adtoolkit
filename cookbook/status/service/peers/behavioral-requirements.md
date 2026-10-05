
### Peer base URL contract (`base-url.ts`)

- **normalize-canonical-form**: `normalizePeerBaseUrl` MUST return the canonical stored form of a well-formed absolute URL: `scheme://host[:port][/path]`, with the scheme and host lower-cased, the scheme's default port dropped, no trailing slash, and no query string or fragment.
- **normalize-unparseable-fallback**: `normalizePeerBaseUrl` MUST NOT throw; when the input does not parse as a URL, it MUST return the trimmed input with every trailing slash stripped.
- **valid-base-url-scheme**: `isValidPeerBaseUrl` MUST return `true` only when the trimmed input parses as an absolute URL whose protocol is `http:` or `https:`, and `false` for a bare host, a relative path, the empty string, or any other scheme (including `ftp:`, `javascript:`, and `file:`).
- **same-base-url-comparison**: `isSamePeerBaseUrl` MUST return `true` for two base URLs if and only if `normalizePeerBaseUrl` produces the identical string for both.
- **self-url-requires-known-public-base-url**: `isSelfPeerUrl` MUST return `false` for every input when `config.publicBaseUrl` is the empty string.
- **self-url-canonical-match**: When `config.publicBaseUrl` is non-empty, `isSelfPeerUrl` MUST return `true` if and only if `isSamePeerBaseUrl(value, config.publicBaseUrl)` is `true`.
- **duplicate-message-constant**: `DUPLICATE_PEER_MESSAGE` MUST be the exported string literal `A peer with that base URL already exists`.
- **duplicate-error-detection**: `isDuplicatePeerError` MUST return `true` when the error passed in, or any object reachable by following up to three levels of its `cause` property, has a `code` field containing `SQLITE_CONSTRAINT_UNIQUE` or a `message` field matching (case-insensitively) `unique constraint failed`.
- **duplicate-error-negative**: `isDuplicatePeerError` MUST return `false` for `null`, `undefined`, an error with an unrelated code such as `SQLITE_CONSTRAINT_NOTNULL`, or an error describing an unrelated failure such as a connection refusal.

### Peer polling (`fetch.ts`)

- **poll-active-peers-only**: `fetchPeers` MUST fetch a snapshot only for the rows `storage.peers.listActive()` returns, never for a peer that is not active.
- **poll-concurrent**: `fetchPeers` MUST issue every active peer's `/snapshot` request concurrently, via `Promise.all` over the active-peer rows, never sequentially.
- **poll-endpoint-and-auth**: For each peer, `fetchPeers` MUST request `${peer.baseUrl}/snapshot` and MUST set an `Authorization: Bearer ${peer.token}` header if and only if `peer.token` is truthy; when `peer.token` is `null` or empty, it MUST send no `Authorization` header.
- **poll-request-timeout**: Each peer's request MUST be bounded by `AbortSignal.timeout(10_000)` (10,000 ms).
- **poll-success-upsert**: When the response's `ok` is `true`, `fetchPeers` MUST upsert a `PeerSnapshotUpsert` for that peer with `reachable: true`, `error: null`, `payload` set to the parsed JSON body, and `overall` set to that body's `overall` field, defaulting to `null` when the field is absent.
- **poll-http-error-becomes-failure**: When the response's `ok` is `false`, `fetchPeers` MUST throw an `Error` naming the HTTP status and catch it within that same peer's own handler, producing the same outcome as poll-failure-upsert.
- **poll-failure-upsert**: On any failure for a peer — a non-`ok` response, a thrown or aborted `fetch` call, or a JSON body that fails to parse — `fetchPeers` MUST upsert a `PeerSnapshotUpsert` for that peer with `reachable: false`, `payload: null`, `overall: null`, and `error` set to the caught error's `message`.
- **poll-never-rejects**: The `Promise` `fetchPeers` returns MUST resolve regardless of how many, or which, individual peers fail; no single peer's failure MUST cause `fetchPeers` itself to reject or prevent any other peer's snapshot from being attempted or stored.
- **poll-fetched-at-per-peer**: Each upserted snapshot's `fetchedAt` MUST be a `Date` captured independently for that peer, at the start of that peer's own fetch attempt.

### Fleet assembly (`fleet.ts`)

- **fleet-member-order**: `assembleFleet` MUST return an array whose first element is the self member and whose remaining elements are one `FleetMember` per row from `storage.peers.listActive()`, in the order that call returns them.
- **fleet-self-member-shape**: The self member MUST have `self: true`, `baseUrl: null`, `reachable: true`, `label`/`overall`/`payload` taken verbatim from the caller-supplied `self` argument's `label`/`overall`/`snapshot` fields respectively, and `fetchedAt` set to the current time at the moment `assembleFleet` is called.
- **fleet-peer-member-lookup**: For each active peer row, `assembleFleet` MUST look up that peer's latest snapshot from `storage.peers.listSnapshots()` by matching `peerId` to the peer's `id`, and MUST populate that member's `overall`/`reachable`/`payload`/`baseUrl`/`label` from that peer row and its matched snapshot (or their documented defaults, see fleet-peer-member-defaults) — never from any other peer's snapshot.
- **fleet-peer-member-defaults**: When no stored snapshot matches a peer's `id`, `assembleFleet` MUST default that member's `overall` to `null`, `reachable` to `false`, `payload` to `null`, and `fetchedAt` to `new Date(0).toISOString()` (the Unix epoch).
- **fleet-inactive-peers-excluded**: `assembleFleet` MUST exclude a peer from the returned array entirely when that peer is not active, even when a snapshot row for it exists in storage.

