
- **SwiftUI / Swift**: a Swift port of markdown.ts/taxonomy.ts has no
  existing Apple counterpart among this repo's sources; the closest
  relative is `MarkdownStore`/`MarkdownRemoteWriter`
  (`packages/apple/AgenticToolkit/Markdown/`), which is a local notes store,
  not a client for this backend surface. A port of `schemasApi` already
  exists as the Apple Hub's `BucketsDataSource`/`BucketsModels`
  (`hub-domain-buckets`) under different model names for the same rows —
  reconcile naming against that recipe rather than reinventing it. Model
  the three clients as non-`Sendable` structs or an `actor` per the
  concurrency guarantees each caller needs, and use `URLSession`/`Codable`
  in place of `authedJson`/`authedRequest`.
- **Jetpack Compose / Kotlin**: use `kotlinx.serialization` for the wire
  shapes and `Retrofit`/`ktor-client` for the HTTP layer; model the
  three-way scoping split (workspace slug, `ecosystemId` parameter, no
  scoping) as three distinct method-parameter shapes rather than one
  shared options object, to keep the divergence visible in the port's own
  type signatures.
- **React / Web (source platform)**: this is the source implementation;
  `authedJson`/`authedRequest` (from `@agentic-toolkit/auth/client` via
  `../http`) and the helpers in `../client-helpers` (`enc`, `compact`,
  `scopeByOwner`, `sortByText`, `workspaceQuery`) are shared with every
  other client in this data package and MUST be reused, not reimplemented.
- **AppKit / UIKit**: the same guidance as SwiftUI applies at the network
  layer (`URLSession`); there is no view-layer concern here since this
  package has no UI.
- **WinUI 3 / .NET**: use `System.Net.Http.HttpClient` for the transport,
  `System.Text.Json` for the wire shapes, `Task`/`async`-`await` for the
  asynchronous operations, and — if a caller needs to observe the result
  set change over time — an `ObservableCollection` wrapped by a view model
  implementing `INotifyPropertyChanged`; this package itself has no
  persistence, so `Windows.Storage` is only relevant to a caller that
  chooses to cache a result, not to this port.

