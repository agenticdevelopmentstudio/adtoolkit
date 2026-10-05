
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| progress-view-001 | constructs-progress-indicator-at-regular-control-size | Construct the component with any view model | The indicator's control size is the platform's regular size |
| progress-view-002 | exposes-progress-indicator-publicly | Any initialized component | The progress indicator is externally accessible and is the same instance added as its child view |
| progress-view-003 | uses-constraint-based-layout | Any initialized component | The view and the progress indicator are both positioned via layout constraints, not the legacy frame-based resizing mechanism |
| progress-view-004 | adds-progress-indicator-as-subview | Any initialized component | The view's children include the progress indicator |
| progress-view-005 | pins-progress-indicator-to-edges | Host view laid out at a fixed frame, e.g. 200×20 | The indicator's resolved frame equals the host view's frame exactly, with zero inset on all four edges |
| progress-view-006 | reflects-initial-progress-value | View model constructed with title "T", progress = 0.5 | Immediately after construction, the indicator is determinate and its displayed value == 0.5 |
| progress-view-007 | reflects-initial-progress-value | View model constructed with title "T" and no progress value (the default) | Immediately after construction, the indicator is indeterminate |
| progress-view-008 | tracks-progress-changes | Construct with progress = 0.2, then set the view model's progress to 0.9 | The indicator's displayed value becomes 0.9; it remains determinate |
| progress-view-009 | tracks-progress-changes | Construct with progress = 0.2, then set the view model's progress to absent | The indicator becomes indeterminate |
| progress-view-010 | shows-determinate-bar-for-non-nil-progress | Set the view model's progress to 42.0 | The indicator is determinate; its displayed value == 42.0; its animation is stopped |
| progress-view-011 | shows-indeterminate-animation-for-nil-progress | Set the view model's progress to absent | The indicator is indeterminate; its animation is running |
| progress-view-012 | continues-updates-while-retained | Construct the view, keep no other external reference to its internal subscription, then set the view model's progress to three different values in turn | The indicator updates on every one of the three changes |
| progress-view-015 | confines-to-ui-thread | Attempt to construct or mutate the component from a thread other than the UI thread | The platform rejects or prevents the attempt (statically or at runtime, depending on platform — see Platform Notes) |

progress-view-006, -008, and -009 use progress values in a 0–1-normalized
range (0.5, 0.2, 0.9) while progress-view-010 uses the source's native 0–100
range (42.0); the component passes the view model's progress value through
to the indicator's displayed value unmodified regardless of scale — the
consumer chooses the scale (see the Design Decision on the indicator's
minimum/maximum values below). progress-view-015 is a static, compile-time
check on platforms that enforce UI-thread confinement statically; on
platforms that enforce it only at runtime, verify it as a runtime check
instead — see Platform Notes.

