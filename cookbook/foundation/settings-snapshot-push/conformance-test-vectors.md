
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-snapshot-push-001 | start-observes-and-pushes, reconnect-repushes | Start with a sender that always succeeds and a snapshot that encodes a value of 1, change the value the snapshot reads to 2 (the test fires no setting-change event), then trigger a reconnect. | The first body is the snapshot with value 1; after the reconnect the last body is the snapshot with value 2 (test: testPushesOnStartAndOnEveryReconnect). |
| settings-snapshot-push-002 | bounded-retry | Three backoffs; the sender fails twice, then succeeds. | The third attempt lands and exactly one body is received (test: testRetriesABoundedNumberOfTimes). If every attempt failed, an error is logged after the third and no further attempts are made. |
| settings-snapshot-push-003 | stop, reconnect-repushes | Start, let the first push finish, stop, then trigger a reconnect. | The reconnect does not push; one body total (test: testAStoppedPushIgnoresReconnects). |
| settings-snapshot-push-004 | sorted-key-encoding | Encode a value with keys `b` and `a`. | The JSON body lists `a` before `b` (test: testEncodesWithSortedKeys). |
| settings-snapshot-push-005 | newest-supersedes | Trigger a push whose sender is slow and failing, then change a setting. | The first push is cancelled and only the second body lands. |
| settings-snapshot-push-006 | snapshot-failure-not-sent | The snapshot builder returns nothing. | An error is logged and the sender is not called. |
| settings-snapshot-push-007 | start-once | Call start twice with the same settings. | The second call logs a warning and does not push again or register another reconnect handler. |
| settings-snapshot-push-008 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

