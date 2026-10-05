
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `readyState` | `string` | none (required) | Vercel deployment build state passed to `vercelPhases`. |
| `readySubstate` | `string \| null \| undefined` | none (required parameter, may be `null`) | Vercel production substate: `PROMOTED`, `ROLLING` or `STAGED`. |
| `target` | `string \| null \| undefined` | none (required parameter, may be `null`) | Vercel deployment target. Only `"production"` enables a deploy phase. |
| `status` (Railway) | `string` | none (required) | Railway deployment status enum passed to `railwayPhases`. |
| `IN_FLIGHT_BUILD_PHASES` | constant | `["building", "queued"]` | Compiled in. Must mirror the server. |
| `IN_FLIGHT_DEPLOY_PHASE` | constant | `"deploying"` | Compiled in. Must mirror the server. |
| `IN_FLIGHT_STATUSES` | constant | `["building", "queued"]` | Compiled in. Web only. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. It has no imports.

