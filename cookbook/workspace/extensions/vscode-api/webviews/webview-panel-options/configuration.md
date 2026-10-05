
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableScripts` | a boolean (optional) | absent (resolves to `false`) | The option as the extension wrote it, passed when constructing this component from as-declared values; absent means the option was absent. |
| `enableForms` | a boolean (optional) | absent (resolves to the resolved `enableScripts` value) | The option as the extension wrote it; absent means the option was absent and follows `enableScripts`. |
| `localResourceRoots` | a list of file locations (optional) | absent (resolves to the extension directory plus the workspace roots once local resource roots are resolved) | The option as the extension wrote it; absent means absent, an empty list means an explicit, honored declaration of no file access. |
| `extensionDirectory` | a file location | none (required) | The owning extension's install directory, given when resolving local resource roots; the first element of the default root list when `declaredLocalResourceRoots` is absent. |
| `workspaceRoots` | a list of file locations | none (required; empty when no project is open) | Every open workspace folder, given when resolving local resource roots; appended after the extension directory in the default root list. |
| `allowingForms` | a boolean | none (required) | Given when building the Content-Security-Policy string; in practice always the resolved `enableForms` of the instance asking for a policy. |

There are no environment variables or settings keys involved: every input arrives as a plain argument, or — for the decoding path — as one of the three wire keys read from whatever data the caller (the pane-state persistence layer, via the app's own pane-state store) hands the decoder.

