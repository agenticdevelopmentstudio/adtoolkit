
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Source order list | a list of issue-source identifiers | `["dns", "http", "glitchtip", "vercel", "cloudflare-pages", "railway", "crunchy"]` | Compiled-in vocabulary and filter order. Changing it means editing this file and the server mirror. |
| Source label map | a map of issue-source identifiers to text labels | the seven labels listed under label-values | Compiled-in display labels. |
| Stuck-deploy threshold | a number | `1800000` | Compiled-in mirror of the server's stuck-build threshold. |
| the issue-source guard operation's argument | a text value | none (required) | The candidate source or platform string to test. |

The module reads no environment variables and no settings keys, imports nothing, and takes no injected dependencies.

