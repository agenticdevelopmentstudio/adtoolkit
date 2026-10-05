
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-store-001 | name-required | save client named `"  "` | throws `missingName` |
| billing-store-002 | name-unique | save project `Site` when another `Site` exists | throws `duplicateName("Site")` |
| billing-store-003 | project-rounding-range | save project with rounding 0 | throws `invalidRounding(0)` |
| billing-store-004 | project-rounding-range | save project with rounding 241 | throws `invalidRounding(241)` |
| billing-store-005 | rate-range | save repo with rate -1 | throws `invalidRate(-1)` |
| billing-store-006 | repo-unique-claim | second repo for the same root and branch | throws `repoAlreadyClaimed` |
| billing-store-007 | project-client-dangling | project with client id `gone` | stored with no client |
| billing-store-008 | save-assigns-id-stamps | save with empty id | stored id non-empty; created = updated |
| billing-store-009 | project-delete-guard | project with 1 entry | throws `projectHasEntries(count: 1)` |
| billing-store-010 | client-delete-guard | client with 2 billed entries | throws `clientHasBilledEntries(count: 2)` |
| billing-store-011 | tracked-flag | repo billing off | `tracked` false |
| billing-store-012 | unassigned-opt-out | unclaimed repo, unassigned tracking off | returns 0; open runs closed; watermark stamped |

