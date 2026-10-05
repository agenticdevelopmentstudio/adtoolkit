
- **SwiftUI**: not applicable to these sources directly — none of the Swift files
  imports SwiftUI; they build form/level/detail value objects that a SwiftUI (or
  AppKit) rendering layer elsewhere consumes unchanged.
- **AppKit / UIKit**: this is one of the two source platforms. The files live under
  `packages/apple/AgenticToolkit/Hub/Features/EcosystemConfig/`
  (`AuthSettingsTopic.swift`, `EcosystemConfigModels.swift`,
  `FeatureFlagsTopic.swift`, `ServerBagsTopic.swift`, `SigninAppsTopic.swift`,
  `StorageTokensRail.swift`, `StorageTokensTopic.swift`), part of the
  `AgenticToolkitHub` sources directory that `project.yml` builds into both
  `AgenticToolkitHub-macOS` and `AgenticToolkitHub-iOS` targets from the same
  source tree — there is no platform-specific branch anywhere in these files. Each
  topic conforms to `EcosystemTopicProvider` and implements
  `child(for:path:rail:)`; every data-source call not covered by the exception
  below is wrapped in `HubError.wrap { ... }`, with specific mappings to
  `HubError.conflict`/`.validation`/`.unexpected` where the requirements above call
  for a distinct message.

  Three requirements exist only because of Swift's concurrency and protocol model
  and apply to this platform alone: `AuthSettingsTopic`, `SigninAppsTopic`,
  `FeatureFlagsTopic`, `ServerBagsTopic`, and `StorageTokensRail`/
  `StorageTokensTopic` are declared `@MainActor final class`, with every method
  that touches their own stored state running only on the main actor. Static
  helpers a `FormAction.perform` closure calls directly —
  `ServerBagsTopic.parsedValue`, `SigninAppsTopic.validateOrigin`/
  `canonicalOrigin`/`canonicalOrigins`, `StorageTokensRail.nameTakenMessage`/
  `createFailedMessage` — are declared `nonisolated`, because `FormAction.perform`
  closures are not `@MainActor`-isolated (per the source's own comments citing
  `FormSpec.swift`). `AuthSettings`, `AuthSettingsUpdate`, `SigninApp`,
  `SigninAppCreate`, `SigninAppUpdate`, `FeatureFlag`, `FeatureFlagCreate`,
  `FeatureFlagUpdate`, `ServerBag`, `ServerBagCreate`, `ServerBagUpdate`,
  `StorageToken`, `StorageTokenCreated`, and `StorageTokenCreate` are all declared
  `Codable, Hashable, Sendable` value types, so they can cross actor boundaries
  (e.g. into a `FormAction.perform` closure) without a data race.

  `AuthSettingsTopic.entry` declares `leadsTo: .detail`; the sign-up options come
  from `SignupMode.allCases`, parsed with `SignupMode(rawValue:)`, with help text
  from `SignupMode.help` (declared in `EcosystemConfigModels.swift`).
  `AuthSettings.allowedProviders: [String]?` decodes from
  `AuthSettingsDataSource.get`'s response but `AuthSettingsTopic.detail`'s form
  specification never surfaces it, and `AuthSettingsUpdate` has no field for it.

  `SigninApp.leaf(in:)` implements leaf computation; the duplicate check compares
  against it case-insensitively; the `clientId` field validates against
  `Slug.pattern` with message `SigninAppsTopic.leafMessage`.

  The flags level's icon is `systemImage: "flag.fill"` when enabled or `"flag"`
  when disabled. `FeatureFlagsTopic.removalMessage` and
  `ServerBagsTopic.removalMessage` are the two distinct removal-message constants
  (**bags-removal-message-distinct-from-flags**). The wrapped JSON value type is
  `JSONValue` (`Support/JSONValue.swift`); its `.int`/`.number` cases are the two
  representations **bags-json-equality-int-number** reconciles;
  `ServerBagsTopic.parsedValue(_:)` discards `JSONValue.parse`'s specific
  `DecodingError`-derived message in favor of the fixed
  `ServerBagsTopic.invalidJSONMessage`; the detail save writes through
  `ServerBagUpdate.value`.

  `StorageTokensRail.child(path:ecosystemID:levelID:title:)` is the shared
  parameterized resolution operation; `StorageTokensRail.createSpec` implements the
  three-way catch and the reveal-once write via `MainActor.run`;
  `StorageTokensRail.aboutText(ecosystemID:)` returns `aboutWithoutEcosystem`/
  `aboutWithEcosystem`; the `name` field validates against `Slug.pattern` with
  `Slug.patternMessage`; `revealedSecrets`/`revealedOnScreen` are the rail's own
  `@MainActor`-isolated stored state, read and cleared by
  `expireRevealedSecret(unless:)`; the post-reveal notice text is
  `ApplicationsTopic.revealMessage`, declared in the sibling Applications module
  (see Design Decisions); date fields format through `HubDates.display`.

  The test suite (`EcosystemConfigTopicsTests.swift`) exercises every Apple topic
  against fakes with concrete assertions for each requirement above.
- **React / Web**: this is the other source platform. `feature-flags.ts`,
  `server-bags.ts`, `client-auth.ts`, `storage-tokens.ts`, and `wire.ts` under
  `packages/web/packages/data/src/ecosystem-config/` (plus shared helpers in
  `http.ts` and `client-helpers.ts`) are plain `fetch`-based clients with no JSX.
  `clientAuthApi` reads and `PUT`s the ecosystem's and each application's
  client-auth settings, sending a `compact`ed body that drops undefined keys but
  keeps an explicit `registration: null`; `ecosystemFeatureFlagsApi.update`/`delete`
  embed `key` in the URL path via `enc()` (`encodeURIComponent`), as do the
  equivalent path segments in `server-bags.ts` and `client-auth.ts`. `tokenPrincipalsApi.list`/`mint`/`revoke`
  accept a `TokenScope` (`ecosystemId`/`workspace`, serialized by `scopeQuery`)
  independently of `MintTokenPrincipalBody.ecosystemId`, a separate body field;
  `TokenPrincipalCreated` (the 201-only body carrying `token`) is a distinct type
  from `TokenPrincipal` (the list-row shape, carrying only `prefix`).
  `EcosystemServerBag.value`/`EcosystemServerBagCreate.value`/
  `EcosystemServerBagUpdate.value` are typed `unknown` in `server-bags.ts`. The UI
  panes and dialog-state modules that call these clients (`FeatureFlagsPane.tsx`,
  `bag-dialog-state.ts`, `flag-dialog-state.ts`, `ApplicationClientAuthSection.tsx`) are not
  among this recipe's given sources, but see Design Decisions for the
  validation-layering split observed there.
- **Compose**: model each Apple protocol as a Kotlin `interface` with `suspend
  fun`s (e.g. `interface FeatureFlagsDataSource { suspend fun list(ecosystemId:
  String): List<FeatureFlag> }`); represent the shared token rail's revealed-secrets
  store as a `MutableStateFlow<Map<String, String>>` so Compose recomposition
  observes the reveal-once transition; model the wrapped JSON value type with
  `kotlinx.serialization.json.JsonElement`, noting the same integral-`Double`-vs-`Long`
  equality pitfall **bags-json-equality-int-number** documents applies to
  `JsonPrimitive` unless normalized the same way.
- **WinUI 3**: model each data-source interface as a C# interface returning
  `Task<T>` (e.g. `Task<IReadOnlyList<FeatureFlag>> ListAsync(string
  ecosystemId)`) backed by `HttpClient` and `System.Text.Json` for
  (de)serialization, mirroring the `async`/`await` shape of Swift's `async throws`
  and TypeScript's `Promise`; back a level's item list with an
  `ObservableCollection<T>` (or a view-model implementing `INotifyPropertyChanged`)
  for a WinUI 3 `ListView`/`ItemsView`. For the shared token rail's reveal-once
  secret, keep the equivalent of `revealedSecrets` as a plain in-memory field on the
  view-model — deliberately never written to `Windows.Storage.ApplicationData` or
  any DPAPI-backed store — so the "shown once" contract this component enforces is
  preserved rather than accidentally persisted.

