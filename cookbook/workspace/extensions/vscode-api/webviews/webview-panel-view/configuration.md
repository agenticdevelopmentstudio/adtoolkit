
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewType` | a string | required at construction | The type this panel was created under, and the key its serializer is registered against. |
| `title` | a string | required at construction | What the pane's chrome calls the panel to begin with. |
| `options` | a webview panel options value | required at construction | What the extension asked for (`enableScripts`, `enableForms`, declared resource roots), with defaults applied. |
| `localResourceRoots` | a list of file locations | required at construction | The directories this panel may read files from, already resolved by the caller. |
| `externalOpenInterval` | a duration in seconds | `0.5` | Minimum seconds between two external link opens from this panel; settable so a test can assert the rate limit without waiting real time, and never changed in production. |
| `openExternalURL` | a function taking a URL | hands the URL to the system's default handler | Injectable so a test can observe external-open calls without opening real browser windows. |

