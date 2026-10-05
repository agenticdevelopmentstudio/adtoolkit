
| Name | Owner | Default | Notes |
|------|-------|---------|-------|
| provider (request configuration) | caller | — (required) | Selects which of the 5 builders/parsers runs. |
| model (request configuration) | caller | — (required, may be empty) | An empty string lets each provider's builder substitute its own default model. |
| apiKey (request configuration) | caller | — (required) | Ignored entirely for the CLI provider. |
| customBaseURL (request configuration) | caller | — (required for `custom`) | Unused by the other four providers. |
| maxTokens (request configuration) | caller | — (required) | Passed through verbatim into every provider's request body / generation config. |
| timeoutInterval (request configuration) | caller | — (required) | Set on the built request for the three HTTP-issuing providers. |
| `aiplugin.artificialAnalysisAPIKey` | the model ranking store | `""` | Plain (non-secure) storage (see Security). Gates whether the store is configured and can resolve ranks. |
| `aiplugin.artificialAnalysisRankCache` | the model ranking store | `[:]` | Per-model-id resolved-rank cache, persisted across launches. |
| adh catalog URL | the model catalog store | `"https://api.agenticdeveloperhub.com/persona/provider-templates?pageSize=100"` | Mutable process-wide value; capped at `pageSize=100`, does not paginate. |
| CLI binary search paths | the local CLI runner | `~/.local/bin/claude`, `/usr/local/bin/claude`, `/opt/homebrew/bin/claude` (first executable wins) | Fixed list, not configurable by a caller. |
| CLI run timeout | caller | — (required) | Drives the terminate-on-timeout watchdog. |
| model ranking store fetch timeout | the model ranking store | `10` seconds | Not caller-configurable. |
| model catalog store fetch timeout | the model catalog store | `10` seconds | Not caller-configurable; applies to all three concurrent fetches. |
| local model metadata fetch timeout | caller, default `5` seconds | `5` seconds | |
| model page store fetch timeout | caller, default `8` seconds | `8` seconds | |
| model listing store fetch timeout | caller, default `8` seconds | `8` seconds | |

