
- **SwiftUI / AppKit / UIKit**: This is one of the two reference
  implementations, under
  `packages/apple/AgenticToolkit/Hub/Features/Ecosystems/`. `EcosystemsModule`
  and its topics are `@MainActor` and `Sendable`-safe under Swift 6 strict
  concurrency; the same `FormSpec`/`HTDVDetail` values these topics build
  are rendered by both the macOS `FormSheet`/`FormViewController`
  (`HTDV/Views/macOS/`) and the iOS `FormSheet+UIKit`/
  `FormViewController+UIKit` (`HTDV/Views/iOS/`) presenters, so this domain
  logic is genuinely shared, unmodified, across macOS and iOS — only the
  presenting view layer differs.

  `Ecosystem`/`EcosystemCreate`/`EcosystemUpdate` (`EcosystemsModels.swift`)
  implement the **Ecosystem record** group above and conform to `Codable,
  Hashable, Sendable, Identifiable` (**ecosystem-model-shape**); their
  decode and derived-property behavior is pinned by
  `EcosystemsModuleTests.swift`'s `testDecodesEcosystemWithMissingIsDefault`
  (**ecosystem-decode-default-fallback**, **ecosystem-identifier-prefix**).

  `EcosystemsDataSource` (`EcosystemsDataSource.swift`) is the injected
  `AnyObject, Sendable` protocol implementing the **Data access boundary**
  group, exposing `list()`, `children(of:)`, `get(id:)`,
  `infrastructureID()`, `identifierExists(_:)`, `create(_:parentID:)`,
  `update(id:_:)`, `delete(id:)`, every one `async throws`.

  `EcosystemsModule` (`EcosystemsModule.swift`) is the top-level
  `HTDVDataSource` implementing the **Root listing and rail navigation**
  group (`rootLevel()`, `item(for:)`, `child(for:)`), pinned by
  `testRootLevelListsProductsWithoutDefaultRows`,
  `testDataSourceFailuresSurfaceAsHubError`,
  `testNotManageableProductShowsNotice`,
  `testProductChildIsTopicsRailInProviderOrder`, and
  `testUnknownProductOrTopicIsEmpty`. `EcosystemTopicProvider`/
  `EcosystemTopicEntry`/`EcosystemTopicGroup`/`EcosystemNoticeTopic`
  (`EcosystemTopic.swift`) implement the **Topic composition** group,
  pinned by `testGroupTopicListsItsChildrenAndDelegates`.

  `EcosystemCreateForm` (in `EcosystemsModule.swift`) implements the
  **Creating an ecosystem** group's form/save-action requirements, pinned
  by `testCreateFormDerivesIdentifierFromInfrastructure`,
  `testCreateFormForChildUsesParentPrefix`, `testCreateActionLowercasesSlug`,
  and `testCreateFormValidationMessages`; its slug length ceiling is the
  `EcosystemCreateForm.slugMaxLength` constant, and slug validation runs
  through `Slug.pattern`/`Slug.isValid`/`Slug.patternMessage`
  (`Support/Slug.swift`).

  `EcosystemSettingsTopic` (`EcosystemSettingsTopic.swift`) implements the
  **Ecosystem settings** group, pinned by `testSettingsFormValuesAndSave`,
  `testSettingsSaveActionLowercasesSlug`, and
  `testSettingsSaveConflictBecomesIdentifierInUse`; the same file also
  defines `ChildEcosystemsTopic`, covering the **Child ecosystems** group,
  pinned by `testChildEcosystemsLevelAndDescent`.

  Every domain error this implementation raises is a `HubError` case
  (`.notFound`, `.conflict`, `.validation`, `.offline`, ...), defined in
  `HubError.swift` and wrapped via `HubError.wrap`
  (`Support/HubError+Wrap.swift`) at every boundary that does not itself
  re-map a specific case — never a raw `Error` reaching a topic or the
  module. Rail navigation position is expressed as an `[HTDVItem]` path
  resolved through `RailPath.id(at:in:)` (`Support/RailPath.swift`);
  `HTDVItem`/`HTDVLevel`/`HTDVDetail` are this recipe's "rail item"/"list"/
  "detail view" vocabulary. This implementation has no feature-picker data
  source in these sources — a port of the picker starts from the other
  reference implementation's contract.
- **React/Web**: This is the other reference implementation, under
  `packages/web/packages/data/src/ecosystems/`. `ecosystemsApi`
  (`ecosystems.ts`) implements the **Ecosystem record** group's row-mapping
  requirements (`toEcosystem`, `addressLeaf`) and the **Reading, listing,
  and updating an ecosystem over the wire**/**Creating an ecosystem** wire-
  shape requirements, pinned by the `ecosystems.test.ts` suite (its
  `toEcosystem`, `ecosystemsApi.workspaceDefaultEcosystemId`, and
  `ecosystemsApi.ecosystemIdForSlug` describe blocks, plus the individual
  cases cited in Conformance Test Vectors above). `identifiersApi`
  (`identifiers.ts`) implements the **Identifier rename and slug
  ownership** group's generic rename/existence-probe requirements;
  `ecosystemsApi.update`'s `slug`-carrying PUT, not `identifiersApi.rename`,
  is the actual ecosystem-rename route
  (**identifier-rename-is-not-ecosystems-renaming-route**).

  `useWorkspaceDefaultEcosystemId` (`use-workspace-default-ecosystem.ts`)
  is a `@tanstack/react-query` wrapper implementing the **Workspace default
  resolution** group; it passes the module-scoped `useToolkitQueryClient()`
  singleton explicitly to `useQuery` rather than reading a client from
  React context (**workspace-default-hook-shared-client**).

  `ecosystem-invitations.ts`'s hooks (`useEcoInvitationRequests`,
  `useEcoPendingUsers`, `useEcoInvites`, `useEcoRowNotes`,
  `useEcoRowHistory`, `useEcoSaveNotes`, `useEcoSendInvitations`,
  `useEcoAddPendingUsers`, `useEcoDeleteRow`) implement the **Invitations
  topic data** group; their row-shape mappers are imported from
  `@agentic-toolkit/adh-ui/invitations-types` rather than defined in this
  recipe (see Design Decisions).

  `ecosystemFeaturesApi` plus its hooks (`ecosystem-features.ts`, tested by
  `ecosystem-features.test.tsx`) implement both **Feature provisioning**
  groups: `catalog`, `list`, `provision`, `remove` are the wire calls;
  `useFeatureCatalog`, `useProvisionedFeatures`, `useProvisionFeatures`,
  `useRemoveFeature`, `useApplyFeatureChange` are the query/mutation hooks.
  Unlike `useWorkspaceDefaultEcosystemId`, these hooks read the query
  client from React context rather than the module singleton
  (**features-hooks-context-client**). This data has no counterpart in the
  other reference implementation.

  Every error this implementation raises is a plain `Error` carrying a
  numeric `.status` (`AuthHttpError`-shaped, from `@agentic-toolkit/auth`'s
  Bearer-token client — see `auth-client`); `isNotFound`/`isConflict`/
  `rethrowConflict` (`client-helpers.ts`, `http.ts`) are the conflict/
  not-found mapping helpers every requirement above that mentions
  surfacing a conflict or a not-found result relies on.
- **Compose / Android**: `OkHttp`/`Ktor` (or `Retrofit`) would replace
  `fetch`/`URLSession` for the web/Apple network calls respectively; a
  `ViewModel` exposing a `StateFlow`/`LiveData` of the resolved ecosystem
  list is the idiomatic equivalent of both `EcosystemsModule.rootLevel()`
  and the react-query list hooks. `androidx.lifecycle.SavedStateHandle` or
  a `Room`-backed repository would be where a native Android port adds a
  local cache neither reference implementation currently has. For the
  feature picker, `coroutineScope { keys.map { async { runCatching {
  remove(it) } } }.awaitAll() }` is the equivalent of `Promise.allSettled`,
  run after the provision call returns.
- **WinUI 3**: `HttpClient` with `System.Text.Json` replaces both
  `fetch` and `URLSession` for every ecosystems/identifiers request this
  recipe documents. A `NavigationView`/`TreeView` with a
  `TreeViewNode`-backed hierarchy is the idiomatic equivalent of the
  Apple rail's recursive `HTDVLevel`/`HTDVChild` model (products → topics
  → child ecosystems, recursing arbitrarily deep per
  child-ecosystems-recurse-via-rail); a `ContentDialog` hosting a form
  built from `Microsoft.UI.Xaml.Controls` (`TextBox` for `name`/`slug`,
  a read-only `TextBlock` for `id`, a multi-line `TextBox` for
  `description`) is the equivalent of `FormSheet`'s create dialog, and a
  second `ContentDialog` with a destructive-styled primary button is the
  equivalent of `FormDeleteAction`'s confirmation flow. `Task`/`async`-
  `await` replaces every `Promise`/Swift `async throws` call; a custom
  `HubError`-equivalent exception hierarchy (or a `Result<T, HubError>`)
  should carry the same `notFound`/`conflict`/`validation` distinctions
  this recipe's error-mapping requirements rely on, since WinUI has no
  built-in typed-error convention of its own to inherit. For the feature
  picker: a `FeaturesClient` over `HttpClient` exposes `GetCatalogAsync`
  (deserialize `{ features }` with `System.Text.Json`, keep server order),
  `ListAsync`, `ProvisionAsync` (one `PostAsJsonAsync` with
  `{ keys }`, returning the full list) and `RemoveAsync` (`DeleteAsync`,
  treating `HttpStatusCode.NotFound` as success), with path segments
  escaped by `Uri.EscapeDataString`. The picker is a `ContentDialog`
  hosting a `ListView` of `CheckBox` items bound to an
  `ObservableCollection<FeatureRow>` whose rows implement
  `INotifyPropertyChanged`; a `comingSoon` row goes in a separate
  "Coming soon" group (a `CollectionViewSource` with `IsSourceGrouped`) with
  `IsEnabled="False"`, and a `provisioning` row shows as already checked.
  Applying a change awaits `ProvisionAsync` first, then
  `Task.WhenAll` over per-key tasks that each catch their own exception
  and return a success flag (plain `Task.WhenAll` throws on the first
  fault, unlike `Promise.allSettled`), then throws
  `Couldn't remove: <keys>` for the failures and always re-reads the list
  in a `finally`. The 30-minute catalog cache has no built-in equivalent:
  keep the catalog and a fetched-at `DateTimeOffset` in a
  session-lifetime service.

