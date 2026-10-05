
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Screen provider | Injected provider | the platform's live-screen provider | Source of live screens. |
| Storage | Injected provider | the settings-backed storage, over the shared settings store | Persistence for the known-set list. |
| Maximum set age | Duration | 180 days | Sets unseen longer than this are dropped on load and on each persist. |
| Clock | Injected clock | the system clock | Injected clock for timestamps, aging and the touch throttle. |
| Settings key | Text (private constant) | `"ScreenSets"` | Settings key holding the encoded set list. |
| Touch persist interval | Duration (private constant) | 60 seconds | Minimum time between persists triggered by a touch. |

