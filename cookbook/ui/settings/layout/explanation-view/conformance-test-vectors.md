
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| explanation-view-001 | renders-caller-text | Construct the view with text "Some text" | The label displays "Some text" |
| explanation-view-002 | wraps-across-lines | Construct the view | The label wraps by word, in multi-line mode, with no maximum line count |
| explanation-view-003 | compresses-and-hugs-loosely-horizontally | Construct the view | The label is free to shrink and wrap to whatever width its container gives it |
| explanation-view-004 | resists-vertical-compression | Construct the view | The label's height is never compressed shorter than its wrapped line count requires |
| explanation-view-005 | fills-view-edge-to-edge | Construct the view, then lay it out inside a fixed-size container | The label's resolved bounds have zero inset from the view's bounds on all four edges |
| explanation-view-006 | exposes-label-property | Construct the view, then access its label from outside the type | The label is accessible and is the same instance built during construction |
| explanation-view-007 | styles-as-secondary-caption | Construct the view | The label's font equals the active theme's `.caption` font; the label's text color equals the active theme's `.secondaryText` color |
| explanation-view-008 | requires-text-at-construction | Attempt to construct the view via a bare/default construction path that supplies no text | Construction is rejected; no usable instance is produced. Not testable as an ordinary in-process assertion on every platform — where the failure mode is a runtime trap rather than a thrown/returned error, this requires a crash-test harness or a compile-time/unavailable check instead. |
| explanation-view-009 | requires-text-at-construction | Attempt to construct the view via a serialization/decoding-based construction path that supplies no text | Construction is rejected; no usable instance is produced. Not testable as an ordinary in-process assertion on every platform — where the failure mode is a runtime trap rather than a thrown/returned error, this requires a crash-test harness or a compile-time/unavailable check instead. |
| explanation-view-010 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

