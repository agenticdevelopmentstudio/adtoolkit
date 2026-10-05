
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-model-001 | sticky-failure | all reads succeed, then the clients read fails | lists unchanged; `lastError` is the unreachable sentence |
| billing-model-002 | overview-fails-alone | overview read fails, other reads succeed | lists updated; previous overview kept; `lastError` nil |
| billing-model-003 | refusal-in-last-error | save of a project refused with "A name is required." | returns nil; `lastError` is that sentence |
| billing-model-004 | success-clears-error | refused write then successful write | `lastError` nil |
| billing-model-005 | consumer-aware-poll | no consumer showing, not first poll | only running timers read |
| billing-model-006 | consumer-aware-poll | a consumer reports showing | all five reads performed |
| billing-model-007 | quiet-when-unchanged | poll with identical data | no change signal |
| billing-model-008 | write-generation | refresh answered after a write began | answers discarded; state not rolled back |
| billing-model-009 | assign-and-roll | assign moves 0 of 2 requested | returns nil; `lastError` is the already-on-a-billable sentence |
| billing-model-010 | assign-and-roll | assign moves 2, promote rolls 2 | returns 2; one refresh |
| billing-model-011 | lookups | segment with no project | `Unassigned` |
| billing-model-012 | lookups | archived and active projects `b`, `a` | `a` only active, sorted |
| billing-model-013 | timestamps | `2026-09-22T14:00:00Z` and `2026-09-22T14:00:00.250Z` | both parse |
| billing-model-014 | timestamps | empty string | nil |
| billing-model-015 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

