
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| telemetry-001 | poll-interval-constant | Read the exported constant | `TELEMETRY_POLL_MS` is `60000` |
| telemetry-002 | first-render-empty, empty-fallback, hook-signature | Empty cache; source never resolves; render the state once | Returned value deep-equals `{ generatedAt: "", errors: [], analytics: [] }` |
| telemetry-003 | hydrate-after-mount, cache-fallback | The cache holds a valid snapshot `S` under `adh-telemetry-v1`; source never resolves | First render returns the empty snapshot; after the post-mount step runs, the state returns a value deep-equal to `S` |
| telemetry-004 | live-wins, persist-on-data, cache-save-format | Cache holds snapshot `A`; source resolves snapshot `B` | The state returns `B`; the cache entry under `adh-telemetry-v1` equals the JSON of `B` |
| telemetry-005 | live-request, query-fn | An overriding client configured with base path `/x`, and a recording transport | Exactly one request to `/x/telemetry` per read, with no extra request options |
| telemetry-006 | live-http-error, single-retry, no-save-on-failure | The source's transport answers 502 every time; cache holds snapshot `A` | The transport is called twice (initial plus one retry); the read's error message is `telemetry 502`; the state returns `A`; the cache still holds `A` |
| telemetry-007 | data-retained-on-error | First poll resolves `B`; next poll (and its retry) answer 500 | The state still returns `B` after the failed poll |
| telemetry-008 | parse-gate | Parsing `null` and parsing an empty string | Both return `null` |
| telemetry-009 | parse-gate | Parsing malformed JSON (`{not json`) | Returns `null` |
| telemetry-010 | parse-gate | Parsing the JSON text of `null`, `{ generatedAt: "x" }`, `{ generatedAt: 1, errors: [], analytics: [] }`, and `{ generatedAt: "x", errors: "nope", analytics: [] }` | Each returns `null` |
| telemetry-011 | parse-projection, snapshot-shape | Parsing the JSON text of a snapshot with one error and one analytics metric | Result deep-equals the original snapshot |
| telemetry-012 | parse-projection | Parsing the JSON text `{"generatedAt":"t","errors":[],"analytics":[],"extra":1}` | Returns `{ generatedAt: "t", errors: [], analytics: [] }` with no `extra` key |
| telemetry-013 | cache-save-best-effort | The cache write throws (quota exceeded); source resolves `B` | No exception reaches the consumer; the state returns `B` |
| telemetry-014 | cache-load-parse | The cache read throws; source never resolves | The state returns the empty snapshot after mount |
| telemetry-015 | shared-poll, per-instance-cache-io | Two consumers use this state under one shared cache; source resolves `B` | One source fetch; both return `B`; the cache write is called twice with the same value |
| telemetry-016 | poll-cadence | State mounted, document visible, first fetch resolved; advance time 60000 ms | A second source fetch occurs |
| telemetry-017 | empty-snapshot | Construct the empty snapshot twice | Two distinct objects, each deep-equal to `{ generatedAt: "", errors: [], analytics: [] }` |
| telemetry-018 | client-only | Load Telemetry State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

