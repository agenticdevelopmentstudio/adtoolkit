
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `panelID` | panel identifier | none (required) | The panel doing the asking, or the panel a URL is being built for; compared against a URL's decoded host during the URL decision. |
| `file` | file location | none (required) | The file the resource-URL naming step names, without checking that it exists or is reachable. |
| `url` | URL | none (required) | The URL a page asked for, exactly as the webview hands it to the URL decision. |
| `localResourceRoots` | list of locations | none (required) | The directories this panel declared it may read files from; an empty list is the default posture and means no file access at all. |

There are no settings keys, environment variables, or dependency-injection
containers involved: every input arrives as a plain argument, and the
declared resource roots are themselves supplied by the caller (the panel's
configuration), not read from any store by this component.

