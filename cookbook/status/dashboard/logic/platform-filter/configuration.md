
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `endpoints` | list of objects, each with a `platform` field (string or absent) | required | Monitored endpoints whose `platform` values drive the unknown and no-platform rows. |
| known-platforms list | ordered list of strings | `vercel`, `railway`, `cloudflare`, `crunchy` | Canonical known-platform list and order; editing it changes both functions. |
| no-platform sentinel | string | `"__none__"` | Sentinel key for an endpoint with no platform. |

No environment variables, settings keys or injected dependencies are read.

