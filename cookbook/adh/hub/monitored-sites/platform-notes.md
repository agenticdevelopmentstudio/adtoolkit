
- **React/Web** (source platform): `packages/web/packages/data/src/monitored-sites/monitored-sites.ts`
  and `wire.ts` hold the client, re-exported by `index.ts` as `@agentic-toolkit/data/monitored-sites`;
  every function is built on `authedJson`/`authedRequest` (from `../http`, re-exporting
  `@agentic-toolkit/auth/client`) and `compact`/`enc`/`sortByText`/`workspaceQuery` (from
  `../client-helpers`). The Dashboards feature (`packages/web/packages/features/dashboards/src/*`) is the
  one current consumer.
- **SwiftUI**: model `SiteGroupView`/`SiteView`/`EndpointView` (and the create/update body shapes) as
  `Codable, Hashable, Sendable` structs, mirroring the sibling Hub domain recipes' models pattern, and the
  twelve functions as `async throws` calls on an `actor` or `@MainActor final class`, with a dedicated
  error type carrying the HTTP status and optional machine code in place of `AuthHttpError`. `ENDPOINT_KINDS`
  becomes a `CaseIterable` `enum` — and, unlike the TypeScript source, a Swift port SHOULD use that enum as
  the `kind` parameter's type rather than a bare `String`, which would close the `endpoint-kind-passthrough`
  gap at compile time rather than reproducing it.
- **AppKit / UIKit**: no direct UI dependency exists in this module; a macOS/iOS Dashboards feature would
  consume the ported client through an injected data-source protocol, the same pattern other Hub domain
  recipes' data sources already use, rather than calling `URLSession` from the view layer.
- **Compose**: model the three wire rows and the six body shapes as Kotlin `data class`es annotated
  `@Serializable`, and the twelve functions as `suspend fun`s on a class built on Ktor or OkHttp, with a
  sealed error type carrying the HTTP status and optional code; model `ENDPOINT_KINDS` as a Kotlin `enum
  class`.
- **WinUI 3**: a .NET port would model `GroupRow`/`SiteRow`/`EndpointRow` and the six body shapes as
  `record`s attributed for `System.Text.Json`, and the twelve functions as `Task<T>`-returning methods on a
  class built on `HttpClient`, attaching `Authorization: Bearer <token>` the way this module's
  `authedFetch` does and refreshing on a `401` the same one-retry way, defining a `MonitoredSitesApiException`
  (status, code) parallel to `AuthHttpError`. Represent `ENDPOINT_KINDS` as a C# `enum EndpointKind { Http,
  Tcp, Icmp }` with a `[JsonConverter]` for the lowercase wire strings, and prefer exposing the endpoint
  list to a bound UI (e.g. a `DataGrid`/`ItemsRepeater`) through an `ObservableCollection<EndpointView>`
  populated after each `Task` completes, rather than a raw array, since WinUI 3's data-binding idiom
  expects change notification a plain `List<T>` does not provide — this is the platform with the least
  existing prior art in this repo for the refresh-and-retry contract, so the WinUI 3 port would need to
  build the equivalent of `authedFetch` itself, not only the twelve request builders.

