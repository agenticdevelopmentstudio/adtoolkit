
Neither file uses a localization mechanism; every user-facing string is a hardcoded English literal returned in a JSON error body. Per this recipe's authoring rules, a hardcoded string is a fact to record, not a gap to excuse.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — `401` | `Unauthorized` | `requireAuth`, `gate.authenticate` resolves `null` |
| n/a — `403` | `Admin required` | `requireAdmin`, context `tier` is not `'admin'` |
| n/a — `429` | `Too many attempts — try again shortly` | `rateLimit`, bucket `count` exceeds `opts.max` |

