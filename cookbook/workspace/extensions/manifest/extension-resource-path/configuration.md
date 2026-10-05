
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `declared` | text | none (required) | The path exactly as an extension manifest, theme file, or contribution point spelled it; passed to resolving a path against a single directory, or the two-directory resolve operation. |
| `directory` | a file-system location | none (required) | The extension's own folder, used as both the resolution base and the containment boundary in the single-directory resolve. |
| `base` | a file-system location | none (required) | The directory `declared` is resolved relative to, in the two-directory resolve; may differ from `root` — a theme's `include` is relative to the including file's own folder, not the extension's. |
| `root` | a file-system location | none (required) | The directory the resolved candidate may not leave, in the two-directory resolve. |
| `component` | text | none (required) | The not-yet-existing child name appended to `parent` when deriving a not-yet-existing child location. |
| `parent` | a file-system location | none (required) | The directory, assumed to already exist, that `component` is appended to when deriving a not-yet-existing child location. |
| `appName` | text | none (required) | The app's display name, passed to composing the application-support location; the function's own contract states it must not be empty, though nothing in the function enforces this (see **application-support-appname-validation** above). |
| `subdirectory` | text | none (required) | The content-kind folder name (for example `"Plugins"` or `"Extensions"`) appended under the app's Application Support directory. |
| `name` | text | none (required) | The dotless folder name passed to composing the home dotfolder location (for example `"agenticplugins"` or `"agenticextensions"`); the leading dot is added by the function. |
| `home` | a file-system location | the process's real home directory | The home directory the home-dotfolder composition resolves against; a caller — typically a test — overrides it so that a test run reads its own fixture rather than a real developer's installed content. |

There are no settings keys or dependency-injection containers involved: every
input arrives as a plain function argument. The one indirect environment
dependency is the process's home directory, consulted only when `home` is
left at its default.

