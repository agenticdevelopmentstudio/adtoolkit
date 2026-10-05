
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| integer-field-view-001 | wraps-number-field-view | Construct the component with a view model whose minimum is 0 and maximum is 10; set the text field's value to "99", then trigger the field's commit action | The text field's value becomes "10" — the clamp visible on the public text field shows the view model's minimum/maximum reached the wrapped field's own bounds |
| integer-field-view-002 | exposes-constituent-views | Construct the component with any view model | The label and text field are accessible from outside the type and are the same instances the wrapped view built |
| integer-field-view-003 | arranges-single-child | Construct the component with any view model, add it to a laid-out view hierarchy of a known size | The public label and text field together occupy the full bounds of the component with no additional outer inset: the label's frame leading edge equals the component's leading edge, and the text field's frame trailing edge equals the component's trailing edge |
| integer-field-view-004 | forwards-editing-end-to-wrapped-field | Set the text field's editing delegate to the component instance itself, type a valid number, then trigger the end-of-editing notification | The wrapped view's commit runs and the new value is stored |
| integer-field-view-005 | default-field-width | Construct the component with no field-width argument | The text field's width constraint is 52 |
| integer-field-view-006 | forwards-label-width | Construct the component with a label width of 80 | The wrapped field's label width constraint is 80 and the label is right-aligned |
| integer-field-view-007 | requires-view-model-at-construction | Attempt construction via a serialization/decoding-based construction path (no view model available) | The call traps with a fatal error (a platform-level runtime trap, not an ordinary in-process assertion); no instance is returned |
| integer-field-view-008 | requires-view-model-at-construction | Attempt construction via the bare/default construction path (no view model supplied) | The call traps with a fatal error (a platform-level runtime trap, not an ordinary in-process assertion); no instance is returned |
| integer-field-view-009 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (at build time or by a runtime check); the component's state is unchanged |

Vector integer-field-view-009 is a static, code-inspection check (a compile-/runtime-enforced thread confinement), not a vector observed by running the program; a port lacking equivalent enforcement should document the gap rather than fabricate a runtime trap.

