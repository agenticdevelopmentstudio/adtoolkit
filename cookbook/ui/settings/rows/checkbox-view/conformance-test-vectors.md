
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| checkbox-view-001 | arranges-row-layout | Construct the component with any view model | The label and the toggle are both part of a single row that is pinned to the component's edges; a flexible spacer sits between the label and the toggle, so the toggle sits at the row's trailing edge; no other layout container appears |
| checkbox-view-002 | links-toggle-accessibility-title | Construct the component with any view model | The toggle's accessible name is linked to the label |
| checkbox-view-003 | initializes-from-view-model | View model title = "Enable Sync", value = true | After init, the label reads "Enable Sync" and the toggle is on |
| checkbox-view-004 | initializes-from-view-model | View model value = false | After init, the toggle is off |
| checkbox-view-005 | commits-toggle-value | Setting-observer value = false; set the toggle on and activate it | The setting-observer value is true after the call |
| checkbox-view-006 | skips-redundant-commits | Wrap the setting-observer value's setter with a spy; set the value to true, then set the toggle on (same value) and activate it | The spy records zero calls: the setter is not invoked, and the value remains true |
| checkbox-view-007 | syncs-on-external-change | After construction, externally change the view model's title and value, then trigger an external-change notification | The label and toggle both update to reflect the new view-model state |
| checkbox-view-008 | exposes-constituent-views | Construct the component, then access its label and toggle properties from outside the type | Both properties are accessible and return the same instances built during init |
| checkbox-view-009 | requires-view-model-at-construction | Attempt construction via a bare/default construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| checkbox-view-010 | requires-view-model-at-construction | Attempt construction via a serialization/decoding-based construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| checkbox-view-011 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |
| checkbox-view-012 | claims-sole-onchange-observer | Register an observer on the view model's external-change notification, then construct the component against that same view model | The notification now points at the component's own handler; invoking it no longer calls the previously registered observer |
| checkbox-view-013 | inherits-native-keyboard-focus | Construct the component in a running app, tab focus to the toggle, then press Space | The toggle receives keyboard focus in the window's tab order and its state flips on Space, per the platform's native toggle-control behavior (unmodified by source) |

Vector checkbox-view-011 is a static, code-inspection check (a
compile-/runtime-enforced thread confinement), not a vector observed by
running the program; a port lacking equivalent enforcement should document
the gap rather than fabricate a runtime trap.

