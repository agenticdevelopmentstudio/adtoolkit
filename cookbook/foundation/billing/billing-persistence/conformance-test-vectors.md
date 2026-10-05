
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-persistence-001 | transaction-atomic | body writes two settings then throws | neither setting is changed; the error reaches the caller |
| billing-persistence-002 | overwrite-guard | upsert of a locked entry with `unlocked` | returns false; the row is unchanged |
| billing-persistence-003 | overwrite-guard | upsert of a user-origin entry with `rollupOwned` | returns false |
| billing-persistence-004 | overwrite-guard | upsert of a new id with any guard | returns true; the row is inserted |
| billing-persistence-005 | activity-cursor | `afterId` 0 for a session with three events | all three instants and the last id |
| billing-persistence-006 | activity-cursor | `afterId` equal to the last id | empty seconds |
| billing-persistence-007 | rollup-candidates | a closed segment of a project with billing off | not returned |
| billing-persistence-008 | segment-context | `tracked` false for a derived run | the segment is stored flagged `untracked` and never appears in rollup candidates |
| billing-persistence-009 | reset-derivation | three derived sessions | returns 3; the next pass re-derives all three |

