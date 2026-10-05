
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `platform` | `string \| null \| undefined` | `null` | The hosting platform identifier (e.g., `vercel`, `railway`, `cloudflare`). Passed to `platformCanon()` for normalization. |
| `projectName` | `string \| null \| undefined` | `null` | The project or site name on the platform. Used in URL construction; `null` yields `null` for platform dashboard. |
| `meta` | `PlatformMeta` | `{}` | Optional platform-specific identifiers: `vercelTeamId`, `railwayProjectId`, `cloudflareAccountId`. Omitted fields are `undefined` and treated as absent (falsy). |
| `endpoints` | `Array<{ url: string; environment?: string \| null }>` | N/A | Array of deployment endpoints. The production endpoint (matched by `environment === 'production'`) is preferred; otherwise the first endpoint is used. Empty array yields `null` for `live`. |

