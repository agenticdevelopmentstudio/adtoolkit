
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | the storage contract (safe for concurrent use) | none — required init parameter | The manager takes no default; the concrete backend (e.g. the markdown-backed conformer) is supplied by the caller. |
| `store` | the markdown document store | none — required init parameter | The markdown-backed conformer takes no default; the caller constructs and owns the document store. |
| `saveDebounce` | duration | 1 second | A fixed internal constant, not externally configurable in the given sources. |
| `pinnedKey` | text | `"pinned"` | The sole frontmatter key the markdown-backed conformer ever writes, likewise a fixed internal constant. |

