
- **SwiftUI**: not a view concern (no UI). An Apple companion backend embedding
  this pattern models the three functions as `async throws` functions (or
  methods on a stateless type) taking a `StorageProtocol`-conforming value and,
  for the config-resolving variant, a `Sendable` `StatusConfig` struct; the
  `VercelMetaSnapshot`/`VercelMetaSyncResult`/`VercelRefreshResult` shapes
  become small `Sendable` structs, with `live: Set<String>?` mirroring the JS
  `Set<string> | null` exactly (nil standing in for the "no verdict" case).
- **Compose**: same non-UI framing as SwiftUI. A Kotlin port models the three
  functions as `suspend fun`s, `VercelMetaSyncResult` as a `data class` whose
  `live: Set<String>?` field is nullable rather than optional, and preserves
  the same ordering (upsert, then read-back, then diff, then conditional
  delete) unless a port deliberately wraps that sequence in a transaction, in
  which case that divergence belongs in that port's own Design Decisions.
- **React/Web** (source platform): lives at
  `packages/web/packages/status-server/src/monitor/refresh-project-meta.ts`;
  three plain exported `async` functions on the Node status backend, depending
  on the in-repo `Storage`/`StatusConfig` port types, `fetchVercelProductionStates`
  (`./fetch-vercel-projects`), and `providerConn` (`./provider-conn`) — none of
  it is client-side React.
- **AppKit / UIKit**: same non-UI framing as SwiftUI — no view renders here; a
  macOS/iOS agent process embedding this pattern has no additional
  consideration beyond the SwiftUI bullet above.
- **WinUI 3**: a .NET port models the three functions as
  `Task<VercelMetaSyncResult> SyncVercelProjectMetaAsync(IStorage storage,
  VercelMetaSnapshot snapshot)`, `Task<VercelRefreshResult>
  RefreshVercelProjectMetaAsync(IStorage storage, VercelEnv env)`, and
  `Task<VercelRefreshResult> RefreshVercelProjectMetaFromConfigAsync(IStorage
  storage, StatusConfig config)`, with `VercelMetaSyncResult.Live` typed as
  `IReadOnlySet<string>?` to preserve the null-means-no-verdict contract from
  `live-null-means-no-verdict`. `env.VERCEL_API_TOKEN` becomes a
  nullable string property read with ordinary null-coalescing rather than a
  JS truthiness check, and `config.secrets` is typed as
  `IReadOnlyDictionary<string, string?>` looked up via `TryGetValue`, the exact
  analogue of the JS bracket lookup returning `undefined` on a miss. The .NET
  Windows App SDK offers no ready-made analogue of this reconcile-and-evict
  pattern; a WinUI 3 host embedding it should still route the actual chunked
  upsert/delete through its own storage layer's transaction API if it wants to
  close the gap described in concurrent-invocation-not-guarded, since neither
  `System.Data.SQLite` nor Entity Framework Core closes that gap automatically
  just by being used in .NET.

