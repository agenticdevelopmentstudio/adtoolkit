
- **SwiftUI**: the source is `packages/apple/AgenticToolkit/macOS/Features/Projects/UserSettings+Projects.swift`,
  part of the macOS-only `AgenticToolkitMacOS` target (`project.yml`),
  importing `AgenticToolkitCore` for `UserSettings`/`UserSetting` and
  referring to its target-mate `GitRepoScanner.defaultRootSkipPatterns`
  with no import needed. The isolation described in
  **main-thread-confinement** comes from the extended type's own primary
  declaration and from the settings-value class itself, both declared
  `@MainActor`, with no `@MainActor` attribute repeated on these three
  properties themselves. Nothing here is SwiftUI-specific — the three
  properties have no view and no state beyond what `UserSetting` already
  provides; a SwiftUI consumer would bind to them through the
  `@ObservedSetting` property wrapper (`Core/SettingStorage/UserSetting.swift`).
- **AppKit / UIKit**: this is the source. The file imports only
  `Foundation` and `AgenticToolkitCore` — no AppKit or UIKit type appears
  in it, so it would compile unchanged behind a UIKit consumer if the
  target were extended to iOS. Its first setting's default, however,
  reaches into `GitRepoScanner.defaultRootSkipPatterns`, and that
  scanner's own recipe records that an iOS port would need a different
  filesystem-access model (a user-picked folder or a security-scoped
  bookmark) rather than the Home-directory scan this default list assumes.
- **Compose**: model the three properties as members of a Kotlin `object`
  backed by Jetpack `DataStore<Preferences>`. `booleanPreferencesKey("highlight_active_pane")`
  and `booleanPreferencesKey("active_pane_follows_mouse")` map directly
  onto the two boolean settings. `DataStore`'s native
  `stringSetPreferencesKey` stores an unordered `Set<String>`, which would
  silently drop the order-preserving, duplicate-permitting semantics
  **no-pattern-validation** and **array-setting-json-encoded** describe
  for the skip-patterns setting — use a JSON-serialized
  `stringPreferencesKey("projectScanSkipPatterns")` instead, and
  decode/encode a `List<String>` at the boundary, to preserve those
  semantics. Mirror the get/set/remove/exists surface with `DataStore`'s
  `Flow`-based read and `edit { }` write.
- **React/Web**: model the three properties as a small typed wrapper over
  `localStorage`, since a browser has no direct filesystem-scanning use
  for the skip-patterns setting but the setting itself is just a stored
  list. Store the skip-patterns setting as a JSON-serialized array under
  the key `"projectScanSkipPatterns"`, and the two booleans as JSON
  `"true"`/`"false"` strings under `"highlight_active_pane"` and
  `"active_pane_follows_mouse"`, parsing at the read boundary since
  `localStorage` only stores strings natively. Use the browser's
  `storage` event for cross-tab change notification in place of the
  synchronous update this file's dependency provides.
- **WinUI 3**: the reason this recipe exists. Model the three properties
  as static members of a settings class backed by
  `Windows.Storage.ApplicationData.Current.LocalSettings.Values`, keyed
  `"projectScanSkipPatterns"`, `"highlight_active_pane"`, and
  `"active_pane_follows_mouse"`. `ApplicationDataContainer.Values` stores a
  `Boolean` natively, so the two flag settings map directly; it does not
  store a `List<string>` directly, so serialize the skip-patterns setting
  with `System.Text.Json.JsonSerializer.Serialize`/`Deserialize` into a
  stored `string` value — the same fallback-to-encoded-payload shape this
  file's dependency uses for binary data. Expose each property through a
  member that raises `INotifyPropertyChanged`, firing synchronously on the
  UI thread, in place of the observable current-value projection. C# has
  no direct equivalent to Swift's compiler-enforced `@MainActor` isolation
  for a static member; document the class as UI-thread-affine by
  convention, or assert `DispatcherQueue.HasThreadAccess` at each entry
  point. Model the active-pane-highlight override relationship with a
  nullable `bool?` on the per-project options type and the same
  precedence C#'s null-coalescing operator expresses directly:
  `options?.HighlightActivePane ?? Settings.HighlightActivePane`.

