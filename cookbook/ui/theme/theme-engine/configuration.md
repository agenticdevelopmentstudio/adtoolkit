
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Theme bytes | Raw bytes | — | Raw theme bytes for byte-based parsing; JSONC, UTF-8/UTF-16, optional BOM. |
| Theme file location | File location | — | Theme file for file-based parsing and importing into storage; the caller vouches for it (not containment-checked). |
| Label | Text | — | The manifest entry's `label`; becomes the theme's name. |
| UI theme | Text | — | The manifest entry's `uiTheme` (`vs`, `vs-dark`, `hc-light`, `hc-black`); decides appearance. |
| Containment root | File location (optional) | The theme file's own directory | Root every `include` must stay inside; the theme contribution point passes the extension's folder. |
| Maximum include depth | Whole number (internal constant) | `8` | Include hops followed before failing with an include-chain-too-deep error. |
| `theme.custom_themes` | Settings-store key, JSON-encoded list of themes | Empty list | Where the settings-backed storage keeps custom and imported themes. |
| `theme.active_theme_id` | Settings-store key, text | The built-in catalog's default theme id | The selected theme's id. |
| Appearance-mode setting | Settings-store setting | host-defined | Read by the default theme manager's automatic-appearance signal for auto-appearance themes. |
| External-change callback | Optional callback | Absent | Callback the theme manager installs; setting it allocates the two setting observers. |
| Settings-store provider | injected provider | host-configured | Backend both keys are persisted in. |

