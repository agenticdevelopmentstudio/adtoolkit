
- **Data collected**: none of this file's own data. Each function receives a caller-supplied credential — the webhook secret (`config.webhooks.vercel` or `config.webhooks.railway`) — plus a caller-supplied `rawBody`/`signature`/`provided` value, purely as function parameters for a single in-memory comparison.
- **Storage**: none. Neither function persists, caches, or otherwise retains the secret, signature, or body beyond the synchronous call; the module holds no variable across calls.
- **Transmission**: none. This file makes no network call and writes no output beyond its `boolean` return value; the secret and signature never leave the process through this file.
- **Retention**: not applicable — nothing outlives the synchronous call that received it; there is no history, cache, or reference to a past verification anywhere in this module.

