
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.CRUNCHY_API_TOKEN` | `string \| undefined` (`env` parameter field, `fetch-crunchy.ts`) | caller-supplied | Crunchy Bridge Bearer token, used directly with no exchange. Absent or empty MUST trigger the dormant no-op per **token-gate**. |
| Request timeout | `number` (inline literal `6_000`, `fetch-crunchy.ts`) | `6_000` ms | Deadline for the single `/clusters` request, via `AbortController`. Not exported; not caller-configurable. |
| `crunchy` cooldown slot | registry entry (external, `provider-cooldown.ts`) | `0` (not cooling down) | Consulted via `rateLimitedUntil("crunchy")` before every request and written via `noteRateLimited("crunchy", ...)` on a 429; owned by `provider-cooldown.ts`, not by this file. `DEFAULT_COOLDOWN_MS` (`60_000`) and `MAX_COOLDOWN_MS` (`900_000`) bound how long a cooldown can last, also owned by that external module. |

