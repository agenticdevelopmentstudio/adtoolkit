
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `searchPaths` (`init(searchPaths:hostVersion:)`) | `[URL]` | none — required | Directories to scan for extension folders; caller-resolved, since `ExtensionRegistry` cannot import the tier that would derive them (see Design Decisions). |
| `hostVersion` (`init(searchPaths:hostVersion:)`) | `SemanticVersion` | none — required | The running host's own version, compared only by `ActivationEventMatcher` and callers outside this file; not the value the engine gate checks against. |
| `ExtensionRegistry.declaredVSCodeVersion` | `SemanticVersion` (static constant, readable from any execution context) | `1.138.0` | The VS Code API surface version every extension's `engines.vscode` is gated against during `loadAll()`/`reload()`. |
| `UserSettings.disabledExtensionIdentifiers` | `UserSetting<Set<String>>` (`"extensions.disabledIdentifiers"`) | `[]` | Persisted, case-insensitively-compared set of identifiers the user has switched off; absence from this set means enabled. |
| Registered `ContributionPoint`s (`register(_:)`) | `[any ContributionPoint]` | `[]` | Points that receive `apply`/`withdraw` calls for each enabled extension's `contributes.*` blocks; caller-supplied, order-preserving. |
| Contributions observers (`addContributionsObserver(_:)`) | `[(token: UUID, handler: () -> Void)]` | `[]` | Handlers called once after every load, reload, enable/disable, or uninstall that changed live contribution state. |

