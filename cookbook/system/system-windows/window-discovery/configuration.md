
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` | session value | required | Supplies the project name (last path component of the working directory, or `"Unknown"`) that windows are matched against. |
| `onWindowActivated` | optional callback | `nil` | Called after a successful focus so the host can close the panel. |
| Heuristic registry | shared singleton | built-in Xcode, Warp, Brave, VS Code, Terminal heuristics plus any registered custom rules | Per-app title-pattern extraction used by matching; not injectable. |
| Window-management engine | private engine instance | created per model | Window enumeration and focus; not injectable. |
| Accessibility permission | system trust state | — | Required for discovery; read via the Accessibility permission's granted state. |

