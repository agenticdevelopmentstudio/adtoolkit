
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| App name | text | none — required | Names the Application Support search location for this app; not validated for emptiness (see `empty-app-name-unvalidated` and its Design Decision) |
| Additional search paths | list of locations | empty | Extra directories appended after the three default locations, in the order given |
| Explicit search paths | list of locations | none — required | Replaces all default-location derivation entirely; used by tests |
| App name (explicit-search-paths form) | text | `"AgenticPlugins"` | Retained alongside explicit search paths, but not consulted to derive any path in this form |
| Built-in plugins location (environment) | location, optional | platform-determined | The plugins directory inside the running app's own bundle; included as a search path only when the platform resolves one |
| Home dotfolder location (environment) | location | current user's home + `.agenticplugins` | Base for the user-level search path |
| Application Support location (environment) | location, optional | platform-determined user data directory | Base for `<app name>/Plugins`; the whole search path is omitted when unavailable |

