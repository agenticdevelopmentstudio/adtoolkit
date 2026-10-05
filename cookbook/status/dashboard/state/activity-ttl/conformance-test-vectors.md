
| ID | Requirements | Input/Precondition | Action | Expected Output |
|----|---|---|---|---|
| activity-ttl-001 | initialization | First render, no stored value | This logic runs for the first time | Returns `ttlMin: 60`, `ttlMs: 3600000`, and a `setTtl` callback |
| activity-ttl-002 | hydration | Durable storage holds `"adh-healthy-ttl": 30` | This logic runs and hydration completes | After hydration, `ttlMin` becomes `30` and `ttlMs` becomes `1800000` |
| activity-ttl-003 | null-as-stored-value | Durable storage holds `"adh-healthy-ttl": null` | This logic runs and hydration completes | After hydration, `ttlMin` is `null` and `ttlMs` is `null` |
| activity-ttl-004 | invalid-value-rejection | Durable storage holds `"adh-healthy-ttl": 45` (not in valid options) | This logic runs and hydration completes | State remains at default (`ttlMin: 60`, `ttlMs: 3600000`) |
| activity-ttl-005 | parse-error-handling | Durable storage holds `"adh-healthy-ttl": "{invalid json"` | This logic runs and hydration completes | The parse failure is caught, state remains default |
| activity-ttl-006 | setTtl-valid | The `setTtl` callback is called with `15` | Observe the state change and the storage write | `ttlMin` is `15`, `ttlMs` is `900000`, durable storage has `"adh-healthy-ttl": 15` |
| activity-ttl-007 | setTtl-null | The `setTtl` callback is called with no value | Observe the state change and the storage write | `ttlMin` is `null`, `ttlMs` is `null`, durable storage has `"adh-healthy-ttl": null` |
| activity-ttl-008 | persistence-error-handling | The durable-storage write fails (e.g., quota exceeded) | The `setTtl` callback is called with `30` | State updates to `ttlMin: 30, ttlMs: 1800000`, the failure is caught, in-memory value persists |
| activity-ttl-009 | ssr-hydration-match | A server-rendered first paint followed by browser hydration | The page is server-rendered and then hydrated in the browser with no stored value | Initial paint matches default (`ttlMin: 60`, `ttlMs: 3600000`), no mismatch warning |
| activity-ttl-010 | client-only | Activity TTL is loaded in a server-only rendering context | Render it | It is unavailable there: the module is marked for client execution only |

