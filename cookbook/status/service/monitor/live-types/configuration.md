
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RAILWAY_GIT_COMMIT_SHA` | environment variable | none (yields `null`) | Read by the producer to populate `LiveSnapshot.monitorVersion`; present only when the monitor process runs on Railway, per **monitor-version-is-railway-commit-or-null**. |
| probe interval | producer-supplied number (ms) | none — always supplied | Surfaced verbatim as `LiveSnapshot.probeIntervalMs`; this file declares the field but supplies no default of its own, per **probe-interval-ms-scales-staleness**. |
| `ProviderKey` set | fixed literal union | `"vercel"` \| `"cloudflare-pages"` \| `"railway"` \| `"crunchy"` | Not caller-configurable; the four keys are declared in this file and MUST be exhaustive per **provider-key-closed-set**. |

