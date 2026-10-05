
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `deploys` (parameter to all four exported functions) | `DeploymentDTO[]` | none — caller-supplied | The full or already-narrowed set of deploy rows the function summarizes or filters; this file fetches none of these rows itself. |
| `ep` (parameter to `deploysForEndpoint`, `latestTerminalForEndpoint`, `failuresForEndpoint`) | `EndpointLike` | none — caller-supplied | The monitored endpoint's own explicit `platform`/`deployProject`/`environment`, read from its stored configuration by the caller before this file sees it. |
| the platform-order list (module-level constant) | `string[]` | fixed 4 entries: `"vercel"`, `"cloudflare-pages"`, `"railway"`, `"crunchy"` | Not configurable at runtime; adding, removing, or reordering an entry requires editing this file. This file reads no environment variable and consults no injected configuration object of its own. |

