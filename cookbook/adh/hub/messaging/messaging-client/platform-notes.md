
- **SwiftUI**: not applicable to these two files directly — `MessagingTopic` returns
  `HTDVLevel`/`HTDVDetail`/`FormSpec` values consumed by the shared `FormViewController`/HTDV
  presentation layer; a SwiftUI-based presenter would consume the same values unchanged, since
  `MessagingTopic.swift` imports no SwiftUI and performs no rendering itself.
- **AppKit / UIKit**: this is the source. `MessagingModels.swift` and `MessagingTopic.swift` live
  in the `Hub` module shared between the `AgenticToolkitHub-macOS` and `AgenticToolkitHub-iOS`
  targets (both declared in `project.yml`, one source set). Neither file imports `AppKit` or
  `UIKit` directly — `MessagingModels.swift` is plain `Foundation`, and `MessagingTopic.swift` adds
  only `AgenticToolkitHTDV`, with the platform-specific `NSViewController`/`UIViewController` split
  handled entirely inside `FormViewController`, one layer below where these types operate.
  Concurrency: `MessagingTopic` is declared `@MainActor final class`, so `child(for:path:rail:)`
  and every private helper it calls run only on the main actor; `MessagingDataSource` is declared
  `AnyObject, Sendable` so a conforming instance can be injected into and called from that
  `@MainActor`-isolated type while performing its own network work off the main actor. Because the
  send form's save closure captures only `Sendable` value types (or a `Sendable` protocol
  reference) and mutates no property of `MessagingTopic` itself, `FormAction.perform`'s plain
  `@Sendable` (non-`@MainActor`) execution context needs no explicit `MainActor.run` hop to run it
  safely — unlike a topic that mutates its own `@MainActor`-isolated state from inside a save
  action. `MessagingTopic` holds no mutable stored property beyond its immutable `dataSource`
  reference, so no lock, queue, or other synchronization primitive is needed within a single
  instance; and the placeholder scan, the template-variables parser, and the fixed send-failure
  message are all declared `nonisolated` because each is called from a context that is not
  guaranteed to be the main actor — the placeholder scan from `MessagingTemplate.placeholders` (a
  plain, non-isolated struct), and the other two from the save closure's `@Sendable`,
  non-`@MainActor` context. Cancellation: every data-source call is a plain `try await` with no
  explicit cancellation handling in either file; Swift's structured concurrency propagates a
  surrounding task's cancellation as a thrown `CancellationError` through the same path any other
  error takes. Deep linking registers no `NSUserActivity`; navigation is entirely through
  `HTDVItem`/`HTDVChild` path arrays. Neither file writes to `UserDefaults` or the Keychain, and
  neither contains an `os_log`, `Logger`, or `print` call; localization uses none of
  `String(localized:)`, a `.strings`/`.xcstrings` catalog, or `NSLocalizedString`.
- **Compose**: a Kotlin port would model `MessagingStatus`/`MessagingTemplate`/`MessagingLogEntry`/
  `MessagingLogPage`/`MessagingSend`/`MessagingSendResult` as immutable `data class`es and
  `MessagingChannel` as a Kotlin `enum class` exposing the same `title`/`providerName`/
  `providerLabel`/`systemImage` accessors, `MessagingTopic` as a class exposing a `suspend fun
  child(...)` returning a sealed `HtdvChild`, and the placeholder regex as a plain `Regex` shared
  between the template model and the topic (mirroring the cross-file call the Swift source makes);
  no view model needs its own coroutine-confined mutable state, since the Swift type holds none
  either.
- **React/Web**: a TypeScript port would use `readonly`-field interfaces for the wire types, a
  plain `MessagingChannel` union/lookup table for the per-channel copy, and `async` functions
  returning `Promise<HtdvChild>` for `child(...)`; the "validate one missing placeholder at a time"
  behavior and the "swallow `status()`, propagate everything else" asymmetry both need to be
  reproduced deliberately, since neither falls out of the language the way `MessagingTopic`'s
  statelessness does.
- **WinUI 3**: a .NET port would model `MessagingStatus`, `MessagingTemplate`, `MessagingLogEntry`,
  `MessagingLogPage`, `MessagingSend`, and `MessagingSendResult` as `record`s (free structural
  equality, mirroring the Swift `Hashable` conformances) and `MessagingChannel` as an `enum` with a
  small extension class or switch-based helper exposing the same `Title`/`ProviderName`/
  `ProviderLabel`/`SystemImage`-equivalent values. `IMessagingDataSource` would expose
  `Task<MessagingStatus> GetStatusAsync(string ecosystemId)`,
  `Task<MessagingSendResult> SendAsync(string ecosystemId, MessagingSend message)`, etc., backed by
  `HttpClient` + `System.Text.Json`. `MessagingTopic`'s equivalent would be a stateless view-model
  class with `async Task<HtdvChild> ChildAsync(...)`, needing no `Dispatcher`/`SynchronizationContext`
  confinement at all — unlike a Hub feature that holds per-instance mutable state on its
  `@MainActor` — and the placeholder regex would be a static, compiled `System.Text.RegularExpressions.Regex`
  shared by the template model and the topic, mirroring the source's one-regex-two-call-sites
  design; the log level's fixed `page: 1` request would translate directly, with the same
  unresolved question of what happens past the first `PageSize` (100) items.

