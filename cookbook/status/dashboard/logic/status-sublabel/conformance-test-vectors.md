
This logic has no reference test suite for these vectors (see Platform Notes). These vectors are derived from the sublabel-building function and the sublabel-phrase table. `row(w)` stands for a row whose `statusWord` is `w`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sublabel-001 | ok-all-healthy | the sublabel-building function called with state `"ok"`, `healthyCount` 12, `servicesLength` 12, no problems | `"12/12 endpoints healthy · no failed builds"` |
| sublabel-002 | ok-not-all-healthy | the sublabel-building function called with state `"ok"`, `healthyCount` 4, `servicesLength` 5, no problems | `"5 endpoints monitored · no failed builds"` |
| sublabel-003 | ok-ignores-problems | the sublabel-building function called with state `"ok"`, `healthyCount` 3, `servicesLength` 3, problems `[row("down")]` | `"3/3 endpoints healthy · no failed builds"` |
| sublabel-004 | ok-strict-equality | the sublabel-building function called with state `"ok"`, `healthyCount` 6, `servicesLength` 5, no problems | `"5 endpoints monitored · no failed builds"` |
| sublabel-005 | ok-all-healthy | the sublabel-building function called with state `"ok"`, `healthyCount` 0, `servicesLength` 0, no problems | `"0/0 endpoints healthy · no failed builds"` |
| sublabel-006 | breakdown-phrase-down, breakdown-phrase-degraded, breakdown-separator | the sublabel-building function called with state `"warn"`, problems `[row("degraded"), row("down"), row("down")]` | `"2 down · 1 degraded"` |
| sublabel-007 | breakdown-phrase-build-failed | the sublabel-building function called with state `"down"`, problems `[row("build failed")]`; the same with two such rows | `"1 failed build"`; `"2 failed builds"` |
| sublabel-008 | breakdown-phrase-deploy-failed | the sublabel-building function called with state `"down"`, problems `[row("deploy failed")]`; the same with three such rows | `"1 failed deploy"`; `"3 failed deploys"` |
| sublabel-009 | breakdown-phrase-deployment-failed | the sublabel-building function called with state `"warn"`, problems `[row("deployment failed"), row("deployment failed")]` | `"2 stale deploys"` |
| sublabel-010 | breakdown-phrase-building | the sublabel-building function called with state `"warn"`, problems `[row("building")]` | `"1 stuck build"` |
| sublabel-011 | breakdown-phrase-platform-unreachable | the sublabel-building function called with state `"down"`, problems one `row("platform unreachable")`; then two such rows | `"1 platform unreachable"`; `"2 platforms unreachable"` |
| sublabel-012 | breakdown-mapped-order | the sublabel-building function called with state `"down"`, problems `[row("building"), row("build failed"), row("down")]` | `"1 down · 1 failed build · 1 stuck build"` |
| sublabel-013 | breakdown-unmapped-verbatim, breakdown-unmapped-after-mapped | the sublabel-building function called with state `"warn"`, problems `[row("expired"), row("down"), row("cert warn"), row("expired")]` | `"1 down · 2 expired · 1 cert warn"` |
| sublabel-014 | breakdown-empty-problems | the sublabel-building function called with state `"warn"`, `healthyCount` 5, `servicesLength` 5, no problems | `""` |
| sublabel-015 | breakdown-group-by-status-word | the sublabel-building function called with state `"warn"`, problems `[row("Down")]` | `"1 Down"` (unmapped, because matching is case-sensitive) |
| sublabel-016 | breakdown-sums-to-problem-count | any non-ok call with a problems list of length 7 over mixed words | the integers in the result add up to 7 |
| sublabel-017 | breakdown-ignores-counts-args | the sublabel-building function called with state `"down"`, `healthyCount` 1, `servicesLength` 9, problems `[row("down")]`, versus `healthyCount` 9, `servicesLength` 9 with the same problems | both `"1 down"` |
| sublabel-018 | sublabel-pure | call with a frozen `problems` list of frozen rows | returns normally; the list and rows are unchanged |

