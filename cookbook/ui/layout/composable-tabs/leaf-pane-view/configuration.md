
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewID` | view identifier | required at init | Which registered content kind this pane hosts. |
| `paneNumber` | integer | required at init | Identifying number passed through to the registry when building content. |
| `workingDirectory` | file-system location | required at init | The directory this pane's content is rooted in; shared by every pane in the same split tree. |
| `layoutOverride` | layout override or unset | unset | Overrides the project's own layout (and its registry) when resolving this pane's content and display name; set by the enclosing split when it is itself overridden, e.g. a pane nested inside another pane's tree. |
| `stateOwnerNodeID` | UUID or unset | unset | Redirects the pane's persisted chrome state to another layout node's row family, for a pane nested inside another pane's content. |
| `thicknessFraction` | number or unset | unset | The fraction of the enclosing split's thickness this pane should occupy; read by the enclosing split, not consulted within this file. |

