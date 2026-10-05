
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| live-timer-row-view-001 | shows-title-and-subtitle | Build with title Acme and a subtitle | Both lines show and the subtitle is visible |
| live-timer-row-view-002 | hides-empty-subtitle | Build with no subtitle | The subtitle line is hidden |
| live-timer-row-view-003 | elapsed-is-a-clock | Start 1 hour 5 minutes 3 seconds before now | The clock reads 1:05:03 |
| live-timer-row-view-004 | elapsed-never-negative | Set the clock earlier than the start | The clock reads 0:00:00 |
| live-timer-row-view-005 | update-swaps-the-model | Update with a new id, title and start 5 minutes ago | The title changes, the clock reads 0:05:00 and the id changes |
| live-timer-row-view-006 | stop-reports-the-id | Press stop | The callback receives the model's id |
| live-timer-row-view-007 | controls-carry-identifiers | Read the stop and clock identifiers for run-1 | timer.run-1.stop and timer.run-1.elapsed |
| live-timer-row-view-008 | origin-tooltips-are-the-callers | Set a custom automatic tooltip | The dot's tooltip changes immediately |
| live-timer-row-view-009 | ticker-ticks-while-started | Start a ticker and deliver two ticks, stop, deliver another | Two ticks arrive and none after stop |
| live-timer-row-view-010 | ticker-start-is-idempotent | Start a ticker twice and deliver one tick | One tick arrives |
| live-timer-row-view-011 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

