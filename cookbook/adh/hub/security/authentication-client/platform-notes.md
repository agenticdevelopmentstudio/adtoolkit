
- **SwiftUI**: not applicable to these files directly — all four types return `HTDVLevel`/`HTDVDetail`/
  `FormSpec` values consumed by the shared `FormViewController`/HTDV presentation layer; a SwiftUI-based
  presenter would consume the same values unchanged, since none of the four imports SwiftUI or performs
  any rendering itself.
- **AppKit / UIKit**: this is the source. `AuthenticationModule.swift`, `ApiTokensRail.swift`,
  `AuthenticationModels.swift`, and `AccessListsTopic.swift` live in the `Hub` module of the
  `AgenticToolkitHub-macOS`/`AgenticToolkitHub-iOS` targets (both declared in `project.yml`, sharing one
  source set); `StorageTokensRail.swift` lives in the sibling `EcosystemConfig` feature folder of the
  same module. None of the five files imports `AppKit` or `UIKit` directly — each is plain
  `AgenticToolkitHTDV` + `Foundation`, with the platform-specific `NSViewController`/`UIViewController`
  split handled entirely inside `FormViewController` (a different file), one level below where these
  types operate. All four roles (`AuthenticationModule`, `ApiTokensRail`, `StorageTokensRail`,
  `AccessListsTopic`) are declared `@MainActor final class`: every stored property (`revealedSecrets`,
  `revealedOnScreen`) and method is read and written only on the main actor, and none declares any lock,
  queue, or other synchronization primitive because none is needed under that isolation (confirmed by
  source declaration — no runtime test needed; this is a compile-time fact, not a Conformance Test
  Vector). Every wire model in `AuthenticationModels.swift` and the storage-token types in
  `EcosystemConfigModels.swift` (`ApiToken`, `ApiTokenCreated`, `ApiTokenCreate`, `AccessGroup`,
  `AccessGroupMember`, `AccessGrant`, `AccessGroupDetail`, `AccessCRUD`, `StorageToken`,
  `StorageTokenCreated`, `StorageTokenCreate`, etc.) is a `Codable, Hashable, Sendable` value type, so an
  instance MAY cross actor-isolation boundaries freely; the four `*DataSource` protocols
  (`ApiTokensDataSource`, `BucketAccessDataSource`, `StorageTokensDataSource`) are `AnyObject, Sendable`,
  so any conforming implementation MUST itself be safe to invoke from the main actor while doing its own
  work off it. Because `FormAction.perform`/`FormDeleteAction.perform` are plain `@Sendable ... async
  throws -> Void` closures (not `@MainActor`), every message constant a save or delete closure reads
  (`noScopeSelectedMessage`, `nameTakenMessage`, `createFailedMessage`) is declared `nonisolated`, and any
  mutation those closures make to a rail's `@MainActor`-isolated state (e.g., `revealedSecrets`) is
  hopped back onto the main actor explicitly (each of `ApiTokensRail` and `StorageTokensRail` does this
  with `await MainActor.run { self?.revealedSecrets[...] = ... }`).
- **Compose**: a Kotlin port would model each `Codable` struct (`ApiToken`, `AccessGroup`,
  `AccessGrant`, `StorageToken`, etc.) as an immutable `data class`; the four rails/topics as classes
  exposing `suspend fun` equivalents of `child(...)` returning a sealed `HtdvChild` class
  (`Level`/`Detail`/`Empty`); `HubError` as a Kotlin `sealed class` with the same eight cases, each
  computing its own `message`; `revealedSecrets` as a `MutableMap<String, String>` guarded by
  confinement to a single `Dispatchers.Main`-bound coroutine scope, mirroring `@MainActor`.
- **React/Web**: a TypeScript port would use `readonly`-field interfaces for the wire types, a
  discriminated-union `HubError` type (`{kind: "conflict", detail: string} | ...`) with a
  `hubErrorMessage()` helper mirroring `HubError.message`, and plain `async` functions returning
  `Promise<HtdvChild>` for each `child(...)`/`level(...)`/`detail(...)` equivalent; the reveal-once
  mechanic would need an explicit teardown (e.g., a router's `onBeforeRouteLeave`/`useEffect` cleanup
  keyed by the outgoing route's first path segment) to reproduce `expireRevealedSecret(unless:)`'s
  "same detail re-renders, anything else expires" rule, since there is no `@MainActor`-style confinement
  to lean on for correctness — the map mutation itself would need to happen on the same thread
  (JavaScript's single-threaded event loop already guarantees this, unlike a truly concurrent runtime).
- **WinUI 3**: a .NET port would model the wire types as `record`s (free structural equality, mirroring
  the Swift `Hashable` conformances) and the four rails/topics as classes with `async Task<HtdvChild>`
  methods, backed by an `HttpClient` + `System.Text.Json` implementation of each `*DataSource` protocol
  (`IApiTokensDataSource`, `IBucketAccessDataSource`, `IStorageTokensDataSource`) with method shapes
  matching the Swift protocols one-to-one (`Task<ApiToken[]> ListAsync()`,
  `Task<ApiTokenCreated> CreateAsync(ApiTokenCreate body)`, etc.); `revealedSecrets` as a
  `Dictionary<string, string>` field on a class instantiated per-window/per-`ContentDialog`, with the
  one-shot expiry implemented in the page's `OnNavigatedFrom` override (or the view model's disposal)
  rather than a `@MainActor`-checked property; `Slug.pattern`/`Slug.patternMessage` port directly to a
  `System.Text.RegularExpressions.Regex` constant plus a `TextBox` validation error string; UI-bound
  collections (the token/group/member/grant lists) become `ObservableCollection<T>` wrapped in a view
  model implementing `INotifyPropertyChanged`, with each list rebuilt (not incrementally patched) on
  every re-fetch, mirroring `access-detail-refetches-every-call`'s "no caching" rule.

