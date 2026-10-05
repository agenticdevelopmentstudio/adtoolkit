
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stepper-view-001 | arranges-row-layout | Construct the component with any view model | The label, the value label, and the stepper are subviews of a single row view, arranged left-to-right as label, spacer, value label, stepper (see Appearance/Padding), that is pinned to the component's edges; no other subview sits outside that row |
| stepper-view-002 | builds-label-from-view-model-title | The view model's title = "Recent Files" | The label reads "Recent Files" after construction |
| stepper-view-003 | builds-value-label-monospaced | Construct with any view model | The value label's font is the system monospaced font (fixed-pitch) |
| stepper-view-004 | resists-value-label-compression | Construct with any view model | The value label's horizontal content compression resistance priority is required |
| stepper-view-005 | configures-stepper-bounds | The view model's minValue = 1, maxValue = 20 | The stepper's minimum is 1.0 and its maximum is 20.0 after construction |
| stepper-view-006 | fixes-stepper-increment | Construct with any view model | The stepper's increment is 1 |
| stepper-view-007 | disables-stepper-wraparound | Construct with any view model | The stepper's wraparound is disabled |
| stepper-view-008 | initializes-stepper-value | The view model's value = 5 | The stepper's value is 5 after construction |
| stepper-view-010 | initializes-value-label-text | The view model's value = 5 | The value label reads "5" after construction |
| stepper-view-011 | updates-value-label-on-change | Set the stepper's value to 7 and trigger its change notification | The value label reads "7" immediately after the call |
| stepper-view-012 | commits-stepper-value | The view model's value = 3; set the stepper's value to 4 and trigger its change notification | The view model's value is 4 after the call |
| stepper-view-013 | skips-redundant-commits | The view model's value = 4; set the stepper's value to 4 (same value) and trigger its change notification | The view model's value setter is not invoked a second time (e.g. no additional write/observer notification is recorded) |
| stepper-view-014 | syncs-on-external-change | After construction, externally change the view model's title, minValue, maxValue, and value, then trigger the view model's change notification | The label, the stepper's minimum/maximum, the stepper's value, and the value label all update to reflect the new view-model state |
| stepper-view-015 | exposes-constituent-views | Construct the component, then access its label, stepper, and value label from outside the type | All three properties are accessible and return the same instances built during construction |
| stepper-view-018 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | The compiler rejects the call at compile time under the platform's UI-thread isolation checking |
| stepper-view-019 | replaces-view-model-onchange | Assign a spy handler to the view model's change-notification callback, then construct the component | Triggering the view model's change notification after construction runs the component's own sync handler; the spy handler is not invoked |

