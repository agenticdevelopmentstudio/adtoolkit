
Constructor parameters (dependency injection) per backend:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Settings store's plain-provider override | provider | the plain persistent provider | Backend for keys with `isSecure == false` |
| Settings store's secure-provider override | provider | the secure persistent provider | Backend for keys with `isSecure == true` |
| In-memory provider's seed values | key/value map | empty | Seed values for tests/previews |
| In-memory secure provider's seed values | key/value map | empty | Seed values, forwarded to its internal in-memory provider |
| Plain persistent provider's backing store | system store | the platform default | Backing store selection |
| Secure persistent provider's service identifier | text or none | none (keeps the default service, the app's bundle identifier) | Secure-store service identifier override |
| Secure persistent provider's access group | text or none | none | Shared secure-store access group |
| Embedded-database provider's path | text | none (required) | Filesystem path of the embedded database |
| Cloud-synced provider's backing store | system store | the platform default | Backing key-value store |
| JSON encoder/decoder (plain persistent, secure persistent, embedded-database, and cloud-synced providers) | encoder/decoder | the default encoder/decoder | Injected for testability |

Setting keys declared on the shared settings store in the given sources:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `editor.show_line_numbers` | boolean | `true` | Show line numbers in the editor |
| `editor.show_overview` | boolean | `true` | Show the overview strip in the editor |
| `editor.show_invisibles` | boolean | `false` | Show invisible characters in the editor |
| `git.executable_path` | text | `/usr/bin/git` | Path to the git executable |
| `git.status_timeout_seconds` | integer | `5` | Timeout, in seconds, for a git status query |
| `git.status_includes_submodules` | boolean | `false` | Whether a git status query includes submodules |
| `theme.active_theme_id` | text | the toolkit's default built-in theme identifier | Active theme identifier; built-in themes are never stored under this key |
| `theme.custom_themes` | array of color themes | empty | User-defined custom themes |
| `launchAtLogin` | boolean | `false` | Whether the app launches at login |
| `launchAtLoginPromptShown` | boolean | `false` | Whether the launch-at-login prompt has been shown |
| `launchAtLoginHintDismissed` | boolean | `false` | Whether the launch-at-login hint has been dismissed |

