
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; slider is at the view model's value with its range set to the view model's minValue/maxValue. |
| Dragging | No custom dragging visual: the slider's default continuous-tracking behavior is left unmodified in source, so it reports a change on every drag tick (not only on release), each tick invoking commits-slider-value/skips-redundant-commits; there is no caption or other view state to update, so the only visible motion is the slider's own native thumb tracking. |
| Pressed | Not applicable: the component renders no button; the slider's own pressed/thumb-drag visuals are the platform's default rendering, not custom to this component. |
| Disabled | Not applicable: the enabled state is never set on the slider or the text field in source; the row is always enabled. |
| Focused | Not applicable / inherited: no custom focus-ring styling is set in source; the slider and label use the platform's default focus-ring behavior when the row is tabbed to. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

