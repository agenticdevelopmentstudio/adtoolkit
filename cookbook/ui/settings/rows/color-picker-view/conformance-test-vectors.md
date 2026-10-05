
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-picker-view-001 | arranges-row-layout | Construct the component with any view model | The label and color well are arranged (with an internal spacer) in a single row that is pinned to the component's edges; no other layout container appears |
| color-picker-view-002 | initializes-from-view-model | View model title = "Accent", color = red | After init, the label reads "Accent" and the color well shows red |
| color-picker-view-003 | commits-color-value | Set the color well to blue and activate it | The view model's color is blue after the call |
| color-picker-view-004 | commits-color-value | Construct with a counting/spy view model stub whose color setter increments a call counter; set the color well to blue and activate it twice in a row with the same color | The setter's call counter increments on both invocations (the second, redundant-value write is not skipped) |
| color-picker-view-005 | syncs-on-external-change | After construction, externally change the view model's title and color, then trigger an external-change notification | The label and color well both update to reflect the new view-model state |
| color-picker-view-006 | exposes-constituent-views | Construct the component, then access its label and color-well properties from outside the type | Both properties are accessible and return the same instances built during init |
| color-picker-view-007 | requires-view-model-at-construction | Attempt construction via a bare/default construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| color-picker-view-008 | requires-view-model-at-construction | Attempt construction via a serialization/decoding-based construction path | The call traps with a fatal error; no instance is returned (a platform-level runtime trap, not an ordinary in-process assertion) |
| color-picker-view-009 | owns-on-change | Construct two instances of this component in turn against the same view model instance, then trigger an external-change notification | Only the second instance's label/color-well update; the first instance's handler was silently replaced and is never invoked |
| color-picker-view-010 | delegates-color-clamping | Set the color well to an out-of-gamut color and activate it | The component writes the reported color into the view model's color unchanged — no clamping call appears in source; any normalization happens inside the color storage type's initializer, one layer below |
| color-picker-view-011 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

