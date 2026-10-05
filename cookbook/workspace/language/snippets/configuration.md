
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `extensionIdentifier` | `String` | none — required | Passed to `SnippetFile.parse` and `SnippetStore.apply`; identifies which extension a snippet, or a recorded failure, came from. `SnippetStore.apply` supplies `manifest.identifier`. |
| `directory` | `URL` | none — required | Passed to `SnippetStore.apply`; the extension's own installed folder, both the base every declared `path` resolves against and the boundary it may not leave. |
| `contributions.snippets` | `[ExtensionManifest.Contributions.Snippet]` (`language: String`, `path: String` pairs) | `[]` when the manifest's `contributes.snippets` key is absent | The declared entries `SnippetStore.apply` reads; each `path` is resolved relative to `directory` and each `language` is the fallback bucket for a snippet whose own `scope` is empty. |
| `SnippetStore.init()` | initializer, no parameters | — | Constructs a store with no applied snippets and no recorded failures; `ExtensionsCoordinator` calls it once and reuses the instance. |

