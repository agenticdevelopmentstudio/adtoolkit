
| Name | Type | Source | Effect |
|------|------|--------|--------|
| `env.VERCEL_API_TOKEN` | `string \| undefined` | `refreshVercelProjectMeta`'s `env` parameter | Presence alone sets `configured`; absence short-circuits to a no-network, no-eviction result. |
| `env.VERCEL_TEAM_ID` | `string \| undefined` | `refreshVercelProjectMeta`'s `env` parameter | Forwarded to `fetchVercelProductionStates`; does not itself gate `configured`. |
| `config.secrets.VERCEL_API_TOKEN` / `config.secrets.VERCEL_TEAM_ID` | `string \| undefined` (by-name lookup) | Resolved via `providerConn(storage, config)` inside `refreshVercelProjectMetaFromConfig` | Same effect as the two rows above, one layer further from the caller. |
| `snapshot.ok` | `boolean` | Caller-supplied to `syncVercelProjectMeta` | `false` upserts (if non-empty) but skips the eviction attempt entirely. |
| `snapshot.configured` | `boolean` | Caller-supplied to `syncVercelProjectMeta` | `false` skips the eviction attempt entirely, independent of `ok`. |

