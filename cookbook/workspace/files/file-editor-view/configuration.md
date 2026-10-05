
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedNode` | file-tree node (optional) | required, supplied by the caller on every render | The file-tree node to show; none, a directory, or a package clears the editor. |
| `documentStore` | document store | required at construction | The app-wide, reference-counted open-document registry; shared across every editor pane in the app. |
| `saveScheduler` | autosave scheduler | required at construction | The app-wide debounced autosave scheduler; shared across every editor pane. |
| `languageServices` | project language services (optional) | required at construction (may be none) | This project's language servers; none disables completion, jump-to-definition, semantic highlighting, and diagnostic annotations for every document this pane opens. |
| `options` | editor options override | required at construction | This pane's resolved line-numbers/minimap ("overview")/invisible-characters display settings; a later change reaches every mounted editor live. |
| `openFile` | callback (optional) | required at construction (may be none) | Callback for showing a cross-file go-to-definition target; none disables jump-to-definition for every document this pane opens. |

