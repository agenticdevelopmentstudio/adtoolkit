
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `contributedView` | `ContributedView` | required at init | The manifest's view declaration this pane represents — its name, kind, and owning extension identifier. |
| `extensionDisplayName` | `String` | required at init | The extension's display name, shown by the placeholder while unresolved. |
| `resolve` | `ContributedWebviewResolving` | required at init | Builds the live panel for this view, or returns nothing when nobody can; called exactly once, on first display. |

