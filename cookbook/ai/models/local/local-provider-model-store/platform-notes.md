
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/AIPluginKit/LocalProviderModelStore.swift`,
  which `import AgenticToolkitCore`s its collaborators
  `LocalModelServer.swift` (same target) and, from Core,
  `ModelCatalogStore.swift`, `ArtificialAnalysisStore.swift`,
  `OllamaModelPageStore.swift`, `OllamaModelMetadata.swift` (which also
  defines `LocalModelMetadataStore`), and the `UserSetting`/`UserSettings`/
  `StorableSetting`/`SettingsStore` settings-storage stack. It has no
  SwiftUI dependency at all — its current consumers,
  `ModelChooserViewController.swift`/`ModelChooserContent.swift`, are
  AppKit, not SwiftUI. Concurrency comes from `@MainActor`, persistence from
  `UserSetting` (UserDefaults-backed by default), networking from
  `URLSession.shared`, and parsing from `JSONDecoder`.
- **Compose**: A Kotlin port has no direct `@MainActor` equivalent; use a
  plain singleton `object` whose mutating functions are confined to
  `Dispatchers.Main.immediate` (or guarded by a `Mutex`) to reproduce the
  same non-interleaved read-modify-write guarantee. Replace the five
  `UserSetting`s with `DataStore<Preferences>` (or a small Room table) keyed
  by the same string names, `kotlinx.serialization.json` in place of
  `JSONDecoder`/`JSONSerialization`, and `OkHttp`/Ktor `HttpClient` with a
  5-second timeout for the two direct GET/POST calls this file makes.
- **React/Web**: A module of plain async functions plus a module-level
  cache object (or `localStorage`/`IndexedDB` for persistence across
  reloads), each cache entry `JSON.stringify`d the way `Codable` serializes
  here. Use `fetch` with `AbortSignal.timeout(5000)` for the two 5-second
  bounds, and preserve `fetchModelInfo`'s ordering with `await catalog();
  await rank(); await (viaOllamaPage ? page() : null);` rather than
  `Promise.all`, since the source deliberately awaits sequentially, not
  concurrently.
- **AppKit / UIKit**: Identical to the SwiftUI note — this type is
  UI-framework-agnostic, and is in fact consumed today from AppKit
  (`ModelChooserViewController`), not SwiftUI. Nothing in the contract
  changes under UIKit.
- **WinUI 3**: Model `LocalProviderModelStore` as a plain static class (or a
  singleton service registered in DI) mirroring the enum-of-statics shape.
  Replace each `UserSetting<T>` with a JSON-serialized string stored in
  `Windows.Storage.ApplicationData.Current.LocalSettings` (its
  `ApplicationDataCompositeValue` does not natively hold nested
  dictionaries, so serialize each cache's value with `System.Text.Json`
  before storing, matching `Codable`'s round-trip here) — never the secure/
  credential-locker equivalent, matching `cache-non-secure-storage`. Use
  `HttpClient` with `Timeout = TimeSpan.FromSeconds(5)` for the `/models`
  and `/api/tags` `GET`s and a `POST` with `JsonContent.Create` for
  `/api/show`. Represent `LocalModelPageStats` as a
  `record struct LocalModelPageStats(string? Downloads, string? Updated)`.
  Reproduce `serialized-atomic-cache-update` by performing each cache's
  read-modify-write inside a `SemaphoreSlim(1, 1)` (or by marshaling onto a
  single `DispatcherQueue`), and reproduce `model-info-sequential-order` with
  `await catalogTask; await rankTask; await pageTask;` — never
  `Task.WhenAll` — so the port preserves the source's deliberate ordering
  rather than parallelizing it.

