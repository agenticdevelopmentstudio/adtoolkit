
- **TypeScript / Node (source)**: this layer is written directly against
  Drizzle ORM's query builder over `@libsql/client`; every atomic guard is
  expressed as a single SQL statement's WHERE/subquery/`ON CONFLICT`
  clause rather than an application-level lock, which is what makes the
  guards safe under Node's single-threaded, interleaved-`await` execution
  model.
- **SwiftUI / AppKit / UIKit**: a client consuming this same contract
  would model each store as a small `actor` (or a `@MainActor`-isolated
  service) exposing `async throws` methods mirroring the port signatures;
  a device-grant's single-use consumption (`consumeApproved`) maps to a
  server round trip whose response is only ever accepted once client-side
  too — the client MUST NOT infer "not consumed yet" from a `nil`
  response without a fresh request, since the guard's authority is the
  server's atomic statement, not client-side caching.
- **Jetpack Compose (Kotlin)**: model each store as a `class` exposing
  `suspend fun` methods returning sealed result types (mirroring
  `"blocked"`/`true`/`false`/`null` as a sealed class rather than a raw
  boolean-or-string union), backed by a Retrofit/Ktor client; the
  webhook-vs-poll ordering guard has no client-side analog — a Compose
  client only ever sees the server's already-reconciled state and MUST
  NOT attempt to re-derive the ordering rule locally.
- **WinUI 3**: model each store as a service class using `HttpClient` for
  the network hop and `System.Text.Json` for (de)serializing the same
  plain domain shapes `ports.ts` defines, with results surfaced through an
  `ObservableCollection<T>` (for list-shaped reads like `listActive`,
  `listOpen`, `listRecentOwned`) and `INotifyPropertyChanged` for
  single-row state (a resolved session, a consumed device grant); every
  method should be `async Task<T>`, and a `"blocked"`/`false`/`null`
  outcome should surface as a discriminated result type rather than a
  thrown exception, matching this layer's own use of return values (not
  throws) for an expected "guard tripped" outcome.

