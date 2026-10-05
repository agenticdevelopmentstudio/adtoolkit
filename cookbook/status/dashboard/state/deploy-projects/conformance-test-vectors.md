
No test in the source exercises this module directly; `use-config-status.dom.test.tsx` mocks the unconfigured-partition read (resolving `{ pending: [...], addable: [], noDomain: [], unconfiguredSites: [] }` or failing with an error whose message is `deploy-projects/unconfigured 502`). The vectors below are traced to the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| deploy-projects-001 | deploy-projects-path, deploy-projects-no-store, deploy-projects-fresh-default | Call the deploy-projects read with a stubbed transport | The transport is called once with path `"/deploy-projects"` and a no-store cache directive |
| deploy-projects-002 | deploy-projects-fresh-path | Call the deploy-projects read with `{ fresh: true }` | The transport is called with path `"/deploy-projects?fresh=1"` and a no-store cache directive |
| deploy-projects-003 | deploy-projects-success | Stub returns ok response with body `{ "projects": [], "verifiedPlatforms": ["vercel"] }` | Resolves to `{ projects: [], verifiedPlatforms: ["vercel"] }` |
| deploy-projects-004 | deploy-projects-http-error | Stub returns response with `ok: false`, `status: 502` | Fails with an error whose message is `deploy-projects 502` |
| deploy-projects-005 | unconfigured-path, unconfigured-no-store | Call the unconfigured-partition read | The transport is called with path `"/deploy-projects/unconfigured"` and a no-store cache directive |
| deploy-projects-006 | unconfigured-fresh-path | Call the unconfigured-partition read with `{ fresh: true }` | The transport is called with path `"/deploy-projects/unconfigured?fresh=1"` |
| deploy-projects-007 | unconfigured-http-error | Stub returns `ok: false`, `status: 502` | Fails with an error whose message is `deploy-projects/unconfigured 502` |
| deploy-projects-008 | unconfigured-success, unconfigured-response-shape | Stub returns ok body `{ "pending": [{ "platform": "vercel", "projectName": "p" }], "addable": [], "noDomain": [], "unconfiguredSites": [] }` | Resolves to the same object |
| deploy-projects-009 | latch-initial-armed, latch-read-at-start | Fresh process start; read the cached state | First request path is `/deploy-projects?fresh=1` |
| deploy-projects-010 | latch-disarm-on-success | After vector 009 succeeds, invalidate `["deploy-projects"]` | Second request path is `/deploy-projects` |
| deploy-projects-011 | latch-kept-on-failure | Fresh process start; first request returns `status: 500`; refetch | Both requests use `/deploy-projects?fresh=1`; query status is error after the first |
| deploy-projects-012 | latch-arm | After a successful fetch, call the arming operation then invalidate the query | Next request path is `/deploy-projects?fresh=1` |
| deploy-projects-013 | hook-enabled-false | Read the cached state with `{ enabled: false }` | The transport is never called |
| deploy-projects-014 | hook-stale-time | Successful fetch, then read again 30 s later | No new request; cached data returned |
| deploy-projects-015 | hook-query-key | Read the cached state under a test cache | The cache's state for `["deploy-projects"]` is defined |
| deploy-projects-016 | hook-return, deploy-projects-http-error | Cached-state fetch returns `status: 503`, retries disabled | Result status is error, error message is `deploy-projects 503` |
| deploy-projects-017 | latch-scope | Latch armed; call the unconfigured-partition read | Path is `/deploy-projects/unconfigured`; latch remains armed |
| deploy-projects-018 | dedup-by-query-key | Two concurrent readers of the cached state under one shared cache | One request is sent |
| deploy-projects-019 | client-only | Load Deploy Projects State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

