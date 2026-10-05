
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| live-timer-list-view-001 | shows-empty-message | Create with Nothing running. and set no timers, then set one, then none | Message visible, hidden, visible again, with zero rows at the end |
| live-timer-list-view-002 | only-manual-can-stop | Set a manual and an automatic timer | Stop buttons are visible and hidden respectively |
| live-timer-list-view-003 | keeps-rows-by-id | Set a timer, keep its row, reload with a changed subtitle | The same row object remains with the new subtitle |
| live-timer-list-view-004 | stop-reports-the-id | Set a manual timer a and press its stop | The list callback receives a |
| live-timer-list-view-005 | ticks-only-while-seen | With visibility false set a timer, then make it visible, then tick | No tick, then one immediately, then one more |
| live-timer-list-view-006 | ticks-only-while-seen | Clear all timers while visible and tick | No tick is delivered |
| live-timer-list-view-007 | no-window-means-not-seen | Ask the default visibility check with no window | False |
| live-timer-list-view-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

