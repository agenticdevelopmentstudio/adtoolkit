
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Recent window count (key `recentWindowsCount`) | integer | `10` | Maximum number of recent documents shown in an Open Recent list; mirrored into the platform's own recent-documents limit. |
| Reopen-on-launch policy (key `reopenOnLaunchPolicy`) | policy (`useSystem` \| `always` \| `never`) | `useSystem` | Whether windows reopen at launch: follow the platform, always, or never. |
| Platform keep-windows-on-quit preference (read-only here) | boolean | `false` when absent | Platform-wide "keep windows on quit" value that `useSystem` defers to; see Platform Notes for how a given platform exposes and inverts it. |
| Platform recent-documents limit (written by the consumer) | integer | Platform's own default until first mirrored | Written when the recent-window-count preference is applied; not written by this concept directly. |
| Shared preference store | preference store | a default store backed by the platform's standard preference mechanism | Injected store both preferences bind to at first access. |

