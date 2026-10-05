
This logic holds hardcoded English strings with no localization layer:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `state-label.down` | `down` | Problem status word |
| `state-label.degraded` | `degraded` | Problem status word |
| `state-label.failed` | `deploy failed` | Problem status word |
| `state-label.stuck` | `deploy stuck` | Problem status word |
| `state-label.stale` | `deployment failed` | Problem status word for a production deploy behind newer unpromoted builds |
| `state-label.unreachable` | `platform unreachable` | Problem status word when a provider API cannot be polled |
| `state-label.erroring` | `app errors` | Problem status word when the app throws while its host answers |

Activity status words arrive already spelled by the server (an activity row's `verb`). Time labels (`just now`, `m`, `h`, `d`), environment badges and source labels come from other logic (see Platform Notes), also English-only.

