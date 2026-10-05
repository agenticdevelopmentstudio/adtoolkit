
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` (parameter to the locality check and the fetch/cached operations) | string | none — required per call | The OpenAI-compatible base URL identifying the target server; used verbatim as the per-base-URL cache key and, after per-operation trimming, as the network request target. |
| `model` (parameter to fetching model info and metadata) | string | none — required per call | The model id to enrich or fetch metadata for; used verbatim as the global cache key for description/page-stats, and forwarded to each collaborator. |
| `viaOllamaPage` (parameter to fetching model info) | boolean | none — required per call | Gates whether the Ollama page lookup (and therefore the returned/cached stats) is attempted at all. |
| `aiplugin.localModelCache` | persisted key, map of base URL to array of model ids | `{}` | Per-base-URL cache of the last successfully fetched model ids. |
| `aiplugin.localModelSizeCache` | persisted key, map of base URL to map of model id to size in bytes | `{}` | Per-base-URL, per-model cache of sizes in bytes from `/api/tags`. |
| `aiplugin.localModelMetadataCache` | persisted key, map of base URL to map of model id to metadata | `{}` | Per-base-URL, per-model cache of `/api/show` metadata. |
| `aiplugin.ollamaModelDescriptionCache` | persisted key, map of model id to description | `{}` | Global (model-id-only) cache of the last resolved description. |
| `aiplugin.ollamaModelPageStatsCache` | persisted key, map of model id to page stats | `{}` | Global (model-id-only) cache of the last resolved Ollama.com page stats. |
| Request timeout (models fetch, sizes fetch) | number (seconds), constant | `5` seconds | Fixed at each call site; not a parameter and not overridable from this component. |
| Loopback host set (model server helper) | set of strings, constant | `{localhost, 127.0.0.1, 0.0.0.0, ::1, [::1]}` | Fixed in the collaborator component; not configurable from this store. |

