
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| choice-slider-view-001 | arranges-row-layout | Construct the component with any view model | The title label, slider, and value label are all part of a single row that is pinned to the component's edges; no other layout container appears |
| choice-slider-view-002 | builds-tick-marks-from-choices | View model has 4 choices | After init, the slider's minimum is 0, its maximum is 3, its tick count is 4, and it is restricted to landing only on those ticks |
| choice-slider-view-003 | flanking-labels-hug-tightly | Construct the component | After init, neither the title label nor the value label expands to absorb extra row width |
| choice-slider-view-004 | slider-expands-to-fill-remaining-width | Construct the component | After init, the slider is the element that absorbs the row's leftover width |
| choice-slider-view-005 | fixes-value-label-width | Choice labels are "Small" and "Extra Small" | After init, the value label's width constraint constant equals the ceiling of "Extra Small"'s rendered width in the value label's font, the widest of the two |
| choice-slider-view-006 | initializes-from-view-model | View model title = "Size", choices = [(label: "Small", value: small), (label: "Large", value: large)], value = large | After init, the label reads "Size", the slider sits at index 1, and the value label reads "Large" |
| choice-slider-view-007 | commits-slider-value | Setting-observer value = choices[0]'s value; move the slider to index 1 and activate it | The setting-observer value equals choices[1]'s value after the call |
| choice-slider-view-008 | ignores-out-of-range-tick | Trigger the slider's action directly with a stub reporting a rounded index equal to the choice count (outside bounds) — a real, bound slider restricted to its own ticks clamps its value into range and can never report an out-of-range value | The setting-observer value is unchanged; no crash occurs |
| choice-slider-view-009 | skips-redundant-commits | Setting-observer value = choices[0]'s value; move the slider to index 0 (same index) and activate it | The setting-observer value's setter is not invoked a second time (e.g. no additional write/observer notification is recorded) |
| choice-slider-view-010 | syncs-on-external-change | After construction, externally change the view model's title and set its value to a value present in the choices, then trigger an external-change notification | The title label, slider position, and value label all update to reflect the new view-model state |
| choice-slider-view-011 | leaves-display-unchanged-for-unmatched-value | After construction, trigger an external-change notification with a value that matches no choice | The slider position and value label remain at whatever they were before the call |
| choice-slider-view-012 | exposes-constituent-views | Construct the component, then access its title-label, slider, and value-label properties from outside the type | All three properties are accessible and return the same instances built during init |
| choice-slider-view-013 | requires-view-model-at-construction | Attempt construction via a bare/default construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| choice-slider-view-014 | requires-view-model-at-construction | Attempt construction via a serialization/decoding-based construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| choice-slider-view-015 | stretches-to-superview-width | Add an initialized component as a subview of a parent container | Once the component is attached to its container, a width constraint equal to the parent's width, at a priority just below the strictest available, is active on the component |
| choice-slider-view-016 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |
| choice-slider-view-017 | claims-onchange-observer | Register a handler on the view model's external-change notification, then construct the component against that same view model | Triggering the notification afterward no longer calls the previously registered handler; only the component's own handler runs |

Vector choice-slider-view-016 is a static, code-inspection check
(a compile-/runtime-enforced thread confinement), not a vector observed by
running the program; a port lacking equivalent enforcement should document
the gap rather than fabricate a runtime trap.

