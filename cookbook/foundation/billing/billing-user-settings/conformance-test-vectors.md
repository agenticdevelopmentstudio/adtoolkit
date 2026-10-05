
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-user-settings-001 | defaults-shared | new holder, read `idleCutoffMinutes` | 15 |
| billing-user-settings-002 | defaults-shared | new holder, read `granularity` | `day` |
| billing-user-settings-003 | defaults-shared | new holder, read `roundingMinutes` and `roundingMode` | 15 and `up` |
| billing-user-settings-004 | defaults-shared | new holder, read `defaultRateCents`, `currency` | 0 and `USD` |
| billing-user-settings-005 | defaults-shared | new holder, read `manualTimerCapHours`, `trackUnassigned` | 8 and true |
| billing-user-settings-006 | keys-from-app | holder built with prefix `x`, set `currency` to `EUR` | the settings table holds `EUR` under the key set's currency key |
| billing-user-settings-007 | keys-from-app | two holders with different key sets | writes to one do not change the other |
| billing-user-settings-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

