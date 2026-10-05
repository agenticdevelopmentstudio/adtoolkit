
| State | Appearance change |
|-------|------------------|
| Default | Scroll view is active; scroll indicators autohide until scrolling or hovering (**scrollers-autohide**). |
| Pressed | Not applicable |
| Disabled | Not applicable |
| Focused | Not applicable |
| Loading | Not applicable |

Not applicable (Pressed/Disabled/Focused/Loading): the component is not
an interactive control, so it has no pressed or enabled/disabled state in
source; construction does not override the platform's default
first-responder behavior, so focus belongs to whatever content is
installed via the set-content operation, not to the panel itself; and the
component has no loading or progress state anywhere in source.

