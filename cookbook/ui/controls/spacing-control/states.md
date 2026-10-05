
| State | Appearance change |
|-------|------------------|
| Default | Shows the current value's numbers in every field/stepper and the matching diagram; redraws and re-lays-out whenever `value` changes. |
| Dragging | A grabbed handle reports pointer travel on every drag event; the control applies the resulting value, then forces an immediate layout and redraw so the diagram tracks the pointer within the same update cycle rather than waiting for the next scheduled display pass. |
| Pressed | A pressed arrow repeats its one-point adjustment on a `0.45`s delay / `0.06`s interval, and its pair's handle is not re-seated while it is pressed, so the button does not slide out from under a held-down pointer mid-repeat. |
| Disabled | Not applicable: no child element is ever put into a disabled state in the implementation; the control has no disabled appearance or behavior. |
| Focused | A focused number field keeps whatever the user has typed until editing ends; Tab/Shift-Tab moves focus to the next/previous field in picture order rather than an inferred focus-traversal order, and Up/Down adjusts that field's value by one point. |
| Loading | Not applicable: the component performs no asynchronous operation in source. |

