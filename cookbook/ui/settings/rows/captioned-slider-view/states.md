
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; slider is at the view model's value; caption shows the formatter applied to the view model's value. |
| Dragging | Caption updates live to the formatter applied to the new value as the slider reports it, ahead of any view-model round trip (see updates-caption-live). |
| Pressed | Not applicable: the component renders no button; the slider's own pressed/thumb-drag visuals are the platform's default rendering, not custom to this file. |
| Disabled | Not applicable: an enabled/disabled state is never set on the slider or text fields in source; the row is always enabled. |
| Focused | Not applicable / inherited: no custom focus-ring styling is set in source; the slider and labels use the platform's default focus-ring behavior when the row is tabbed to. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

