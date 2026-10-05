
Vectors pf-001 to pf-006 are derived from the implementation's test suite (see Platform Notes). The rest trace to the options and all-keys functions directly.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pf-001 | known-platforms-always, known-platforms-order | endpoints with platforms `vercel`, `vercel`, `cloudflare` | keys `["vercel","railway","cloudflare","crunchy"]` (railway present with zero endpoints) |
| pf-002 | known-platforms-always | empty endpoint list | keys `["vercel","railway","cloudflare","crunchy"]` |
| pf-003 | none-row-conditional | endpoints with platform `vercel` | no row has the no-platform sentinel as its key |
| pf-004 | none-row-conditional, none-row-last, null-maps-to-sentinel | endpoints with platforms `vercel`, absent | last row's key/label equal the no-platform sentinel and `"no platform"` |
| pf-005 | unknown-platforms-appended, none-row-last | endpoints with platforms `fly`, absent | keys `["vercel","railway","cloudflare","crunchy","fly","__none__"]` |
| pf-006 | known-platform-no-duplicate | endpoints with platforms `railway`, `railway` | keys `["vercel","railway","cloudflare","crunchy"]` |
| pf-007 | all-keys-contents, all-keys-ignores-data | call the all-keys function | set equal to `{"vercel","railway","cloudflare","crunchy","__none__"}` |
| pf-008 | known-platform-label | second row of the options for an empty endpoint list | key and label both `"railway"` |
| pf-009 | unknown-platforms-order, unknown-platforms-deduplicated | endpoints with platforms `render`, `fly`, `render` | keys `["vercel","railway","cloudflare","crunchy","render","fly"]` |
| pf-010 | known-match-exact | endpoints with platform `"Vercel"` | keys `["vercel","railway","cloudflare","crunchy","Vercel"]` |
| pf-011 | all-keys-fresh-set | call the all-keys function, clear the result, call it again, read its size | `5` |
| pf-012 | none-sentinel | read the no-platform sentinel value | `"__none__"` |
| pf-013 | options-synchronous | call the options function with an immutable input list | returns rows without throwing; input unchanged |
| pf-014 | selection-contract | selection equal to the full known-key set; endpoints with platforms `railway`, absent, `fly` | `railway` and the absent-platform endpoint pass; `fly` endpoint does not |
| pf-015 | no-errors, single-threaded | call both functions with valid input | return a value synchronously (not a deferred result); nothing thrown |

