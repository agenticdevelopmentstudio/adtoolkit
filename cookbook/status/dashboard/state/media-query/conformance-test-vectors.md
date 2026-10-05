
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| media-query-001 | initial-value | Viewport matches `"(max-width: 760px)"`; inspect the value from the very first evaluation, before any subscription is established | `false` |
| media-query-002 | ssr-value | Render, in a server-rendering pass, something that evaluates `"(min-width: 761px)"` | Rendered output reflects `false` |
| media-query-003 | mount-sync | The media-query facility reports a match for the query; establish the subscription and let it settle | Returned value becomes `true` |
| media-query-004 | mount-sync | The media-query facility reports no match; establish the subscription and let it settle | Returned value stays `false` |
| media-query-005 | change-subscription | After subscribing with no match, deliver a change notification reporting a match | Returned value becomes `true`; a following notification reporting no match returns it to `false` |
| media-query-006 | unsubscribe-on-unmount | Subscribe, then stop using it | The environment's unsubscribe operation is called once, removing the same handler that was registered |
| media-query-007 | query-change-resubscribe | Re-evaluate with the query changed from `"(max-width: 760px)"` to `"(min-width: 761px)"` | Old listener removed, the media-query facility asked about the new query, new listener added, value set to the new query's match result |
| media-query-008 | stable-query-no-resubscribe | Re-evaluate with the same query string | The media-query facility is not asked again; the subscribe count is unchanged |
| media-query-009 | stale-value-on-query-change | Subscribed with query A (matches); the query input changes to query B (no match) | Immediately after the change it still returns `true`, then `false` once the subscription updates |
| media-query-010 | no-environment-guard | The media-query facility is absent; establish the subscription | Evaluation fails with an error; Media Query does not return a fallback |
| media-query-011 | client-only | Load Media Query in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

