
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; when the view model's value matches a choice, the slider sits at that choice's tick and the value label shows that choice's name. |
| Dragging | The slider's on-screen thumb snaps to the nearest tick continuously as it is dragged. The value label's text, however, updates only once the committed value round-trips through the view model's external-change notification — the setting observer delivers that callback on a *later* turn of the UI event loop, not synchronously inside the slider's action — so the value label can lag one turn behind the slider's visible tick position. |
| Pressed | Not applicable: the component renders no button; the slider's own pressed/thumb-drag visuals are the platform's default rendering, not custom to this file. |
| Disabled | Not applicable: an enabled flag is never set on the slider or text fields in source; the row is always enabled. |
| Focused | Not applicable / inherited: no custom focus-ring styling is set in source; the slider and labels use the platform's default focus-ring behavior when the row is tabbed to. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

