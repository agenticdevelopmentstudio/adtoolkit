
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| header-view-001 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |
| header-view-002 | exposes-title-label | Construct the component with title "Section" | Its label is accessible from outside the type and is the same label instance the component displays |
| header-view-005 | creates-title-label-with-secondary-caption-style | Construct the component with title "Section" | The label's color role is the theme's `.secondaryText` role and its text role is `.caption` |
| header-view-006 | sets-title-label-initial-text | Construct the component with title "General" | The label displays "General" |
| header-view-007 | pins-title-label-to-all-four-edges | Construct the component with title "Section", add it inside a fixed 200×20-point container, and force a layout pass | The label's resolved bounds equal the component's bounds exactly (top, leading, trailing, and bottom all at zero offset) |
| header-view-008 | requires-title-at-construction | Attempt to construct the component via a bare/default construction path that supplies no title | Construction is rejected; no usable instance is produced. Not testable as an ordinary in-process assertion on every platform — where the failure mode is a runtime trap rather than a thrown/returned error, this requires a crash-test harness or a compile-time/unavailable check instead. |
| header-view-009 | requires-title-at-construction | Attempt to construct the component via a serialization/decoding-based construction path that supplies no title | Construction is rejected; no usable instance is produced. Same testing caveat as above. |

