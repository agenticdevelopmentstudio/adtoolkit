
- **SwiftUI**: not applicable to these files directly — the applications topic
  returns level/detail/form values consumed by the shared form/HTDV presentation
  layer; a SwiftUI-based presenter would consume the same values unchanged, since
  `ApplicationsTopic.swift` imports no SwiftUI and performs no rendering itself.
- **AppKit / UIKit**: this is the source. `ApplicationsDataSource.swift`,
  `ApplicationsModels.swift`, and `ApplicationsTopic.swift` live in the `Hub` module
  shared between the `AgenticToolkitHub-macOS` and `AgenticToolkitHub-iOS` targets
  (both declared in `project.yml`, one source set). None of the three files imports
  `AppKit` or `UIKit` directly — each is plain `Foundation` (`ApplicationsTopic.swift`
  also imports `AgenticToolkitHTDV`), with the platform-specific
  `NSViewController`/`UIViewController` split handled entirely inside
  `FormViewController`, one layer below where these types operate.

  `ApplicationsDataSource` is declared `AnyObject, Sendable` and exposes:
  `list(ecosystemID:)`, `get(id:)`, `create(_:)`, `update(id:_:)`, `delete(id:)`,
  `renameIdentifier(_:to:)`, `schemaGrants(applicationID:)`,
  `setSchemaGrants(applicationID:_:)`, `tokens(applicationID:)`,
  `createToken(applicationID:name:)`, and `revokeToken(applicationID:tokenID:)`.
  `BucketsDataSource` is likewise `AnyObject, Sendable`. `ApplicationsModels.swift`
  holds the `Codable`/`Sendable` wire types `Application`, `ApplicationCreate`,
  `ApplicationUpdate`, `ConsumerKind`, `ApplicationToken`, `ApplicationTokenCreated`,
  plus the domain-only, deliberately non-`Codable` grant types `CrudPermissions`,
  `TableGrant`, `SchemaGrant` (kept off the wire per
  **grant-types-are-domain-only**). `ConsumerKind.init(from:)` implements the
  unrecognized-value fallback (**consumer-kind-decoding**); the two form-side
  fallbacks live in `ApplicationsTopic.createSpec`'s save action and
  `settingsDetail`'s save action, and `Self.kindOptions` is built from
  `ConsumerKind.allCases`. `CrudPermissions.wire`, `CrudPermissions.init(wire:)`,
  `CrudPermissions.summary`, and `CrudPermissions.isWithin(_:)` implement the
  wire-order, parsing-tolerance, summary-text, and ceiling-check requirements
  respectively. `Slug.pattern`/`Slug.patternMessage` back the shared slug-format
  rule, and `CrudPermissions.readOnly` is the default grant permission set.

  `ApplicationsTopic` is declared `@MainActor final class` conforming to
  `EcosystemTopicProvider`; every thrown error is normalized via `HubError.wrap(_:)`,
  with specific mappings to `HubError.conflict`/`.notFound`/`.validation` where the
  requirements above call for a distinct message. `child(for:path:rail:)` is the
  rail path resolver; `RailPath.id(at: 1, in: path)` reads the section id.
  `revealedSecrets` (`[String: String]`) and `revealedOnScreen` (`String?`) are the
  topic's own `@MainActor`-isolated stored state; `expireRevealedSecret(unless:)`
  implements the secret-expiry check. `listLevel(for:)`, `applicationLevel(for:)`,
  `grantsLevel(_:ecosystem:)`, and `grantLevel(_:grant:)` implement the four
  listings; `createSpec(for:)`, `settingsDetail`, and `addSchemaSpec` implement the
  three forms; `rewriteGrant` implements the schema/table grant whole-list rewrite.
  `ApplicationsTopic.deletedSchemaLabel`, `.noSchemasMessage`, `.rowLevelMessage`,
  and `.revealMessage` hold the four named message constants.

  Three requirements exist only because of Swift's concurrency model and apply to
  this platform alone: `ApplicationsTopic` MUST be declared `@MainActor final
  class`, with its stored state (`revealedSecrets`, `revealedOnScreen`) and every
  method running only on the main actor, so no lock, queue, or other synchronization
  primitive is needed to serialize reads and writes of that state within a process.
  `ApplicationsDataSource` and `BucketsDataSource` MUST be declared `AnyObject,
  Sendable`, so a conforming instance can be safely injected into and called from
  the `@MainActor`-isolated `ApplicationsTopic` while performing its own network
  work off the main actor. Because `FormAction.perform` is a plain `@Sendable async
  throws -> Void` closure, not `@MainActor`-isolated, a save action that mutates
  `revealedSecrets` (the "New token" create action) MUST hop that mutation onto the
  main actor explicitly via `await MainActor.run { ... }` — it cannot write the
  `@MainActor`-isolated property directly from the closure's own execution context.

  Cancellation: every `ApplicationsDataSource`/`BucketsDataSource` call is a plain
  `try await` with no explicit cancellation handling in these files; Swift's
  structured concurrency propagates a surrounding task's cancellation as a thrown
  `CancellationError` through the same `try await` path that any other error takes,
  so it is passed through `HubError.wrap(_:)` like any other failure.

  The test suite (`ApplicationsTopicTests.swift`) exercises every operation against
  a fake data source whose spy properties are named `creates`, `renames`,
  `grantWrites`, `grants`, `deletes`, `tokenCreates`, `tokenRevokes`, and
  `createFailure`/`failure`/`grantWriteFailureIndex`; fixtures use
  `Application.fixture()`.

  Deep linking: none of these three files registers a `URL` scheme, universal link,
  or `NSUserActivity`; navigation is entirely through `HTDVItem`/`HTDVChild` path
  arrays. Localization: no `String(localized:)`, `.strings`/`.xcstrings` catalog, or
  `NSLocalizedString` call appears; every literal is a plain Swift `String`.
  Logging: no `os_log`, `Logger`, or `print` call appears. `ApplicationTokenCreated`
  declares no `CustomStringConvertible`/`CustomDebugStringConvertible` override, so
  its synthesized default description includes the secret in full;
  `ApplicationsTopic.swift` never logs or prints a `created` value.
- **Compose**: a Kotlin port would model `Application`/`ApplicationCreate`/`ApplicationUpdate`/
  `ApplicationToken`/`ApplicationTokenCreated` as immutable `data class`es, `ConsumerKind` as a
  Kotlin `enum class` with a custom deserializer mirroring the `.developer` fallback,
  `CrudPermissions`/`TableGrant`/`SchemaGrant` as plain (non-`@Serializable`) domain classes kept
  out of the wire-decoding path on purpose, and `ApplicationsTopic` as a class exposing a
  `suspend fun child(...)` returning a sealed `HtdvChild`; `revealedSecrets` becomes a
  `MutableMap<String, String>` confined to a single `Dispatchers.Main`-bound coroutine scope,
  mirroring `@MainActor`.
- **React/Web**: a TypeScript port would use `readonly`-field interfaces for the wire types, a
  runtime narrowing function for `ConsumerKind` (mirroring the `.developer` fallback instead of
  `zod`'s default throw-on-mismatch behavior), plain objects (not classes) for
  `CrudPermissions`/`TableGrant`/`SchemaGrant` kept out of any `JSON.stringify` path that reaches
  the network, and `async` functions returning `Promise<HtdvChild>` for `child(...)`; the
  reveal-once mechanic needs an explicit teardown (a router's route-leave hook keyed by the
  outgoing path's token id) to reproduce `expireRevealedSecret(unless:)`'s "same detail re-renders,
  anything else expires" rule — JavaScript's single-threaded event loop already gives the map
  mutation itself the safety `@MainActor` provides in Swift, so no extra confinement primitive is
  needed for that part.
- **WinUI 3**: a .NET port would model `Application`, `ApplicationCreate`, `ApplicationUpdate`,
  `ApplicationToken`, and `ApplicationTokenCreated` as `record`s (free structural equality,
  mirroring the Swift `Hashable` conformances), `ConsumerKind` as an `enum` with a custom
  `JsonConverter` that narrows an unrecognized `System.Text.Json` string to `Developer` instead of
  throwing, and `CrudPermissions`/`TableGrant`/`SchemaGrant` as plain classes with no
  `[JsonPropertyName]`/serialization attributes at all — kept deliberately unreachable from
  `System.Text.Json.JsonSerializer` the same way the Swift types are kept off `Codable`.
  `IApplicationsDataSource` would expose `Task<Application[]> ListAsync(string ecosystemId)`,
  `Task<ApplicationTokenCreated> CreateTokenAsync(string applicationId, string name)`, etc., backed
  by `HttpClient` + `System.Text.Json`. `ApplicationsTopic`'s equivalent would be a view-model class
  with `async Task<HtdvChild> ChildAsync(...)`; `revealedSecrets` becomes a
  `Dictionary<string, string>` field on a view model instantiated per-window/per-`ContentDialog`,
  with the one-shot expiry implemented in the page's `OnNavigatedFrom` override (or the view
  model's `Dispose`) rather than a `@MainActor`-checked property, and UI-bound lists
  (`ObservableCollection<T>`) rebuilt wholesale on every re-fetch rather than incrementally patched,
  mirroring the whole-list-rewrite pattern in `schema-save-rewrites-whole-list`.

