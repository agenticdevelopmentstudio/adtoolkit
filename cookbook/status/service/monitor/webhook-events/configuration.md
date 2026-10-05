
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `event` (parameter to `mapVercelDeployEvent`) | `unknown`, cast to the module-private `VercelEvent` shape | none — caller-supplied per call | The already-JSON-parsed Vercel webhook request body, handed in by `routes/hooks.ts` (external) after HMAC-SHA1 signature verification (`webhook-verify.ts`, external). |
| `event` (parameter to `mapRailwayDeployEvent`) | `unknown`, cast to the module-private `RailwayEvent` shape | none — caller-supplied per call | The already-JSON-parsed Railway webhook request body, handed in by `routes/hooks.ts` (external) after shared-secret verification. |
| `VERCEL_STATE` (module constant) | `Record<string, { readyState: string; readySubstate: string \| null }>` | the fixed 7-entry table under Vercel Event-Type Lookup | Not exposed to the caller or the environment; the sole source of the mapping from a Vercel event `type` string to a `readyState`/`readySubstate` pair. |

