
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rootURL` | a file-system location | — (required) | The directory the scan operation scans and the open operation resolves `project.path` against; fixed for the life of a detector instance. |
| `project` | a detected-project value | — (required) | The marker the open operation opens. |
| `url` | a file-system location | — (required) | The file the language-resolution operation resolves a code-language value for. |
| `language` | a code-language value | — (required) | The value the LSP-language-id remap remaps to an LSP `languageId`. |
| `CustomFileTypeMappings.activeDefaultsKey` | a settings-key string | the host-configured default mappings key | Settings key the language-resolution operation indirectly reads through the mapping lookup; host apps override it at startup so per-window/per-project custom mappings can be kept separate. |
| `CustomFileTypeMappings.contributedProvider` | an optional callback taking an extension string and returning a mapping, or none | none | Optional extension-contributed mapping source the mapping lookup falls back to when the user's own saved mappings do not claim an extension; set once by the host, not read directly by the language-detection component. |

