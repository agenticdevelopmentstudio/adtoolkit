
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `view` | contributed view | required at init | The extension's manifest-declared tree view this pane hosts; drives the placeholder, the pane title's fallback, and the tree's accessibility-id prefix (registry id). |
| `extensionDisplayName` | string | required at init | Shown by the placeholder while no provider has registered; not consulted again once a tree is shown. |
| `resolve` | callback | required at init | Invoked exactly once, once the view is ready, to supply the data source. It is never invoked again; a later replacement arrives only through the provider-replacement signal on that data source (`provider-replacement-swaps-source`). |
| `childrenBudget` | duration (seconds) | `30` | How long a single `getChildren` ask may take before its branch is treated as unanswered; settable, intended for tests. |

