
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; toggle state reflects the view model's value. |
| On | Toggle is on, drawn as the platform's system on-track appearance; set on init when the view model's value is true, and on any user or external change that sets the value true. |
| Off | Toggle is off, drawn as the platform's system off-track appearance; set on init when the view model's value is false, and on any user or external change that sets the value false. |
| Pressed | Not applicable: the component renders no button; the toggle's own drag/press animation while switching on or off is the platform's default rendering, not custom to this file. |
| Disabled | Not implemented in the component; an enabled flag is never read or set on the label or toggle in source. A caller may set the toggle's enabled state directly through the public toggle property, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by the component; any focus ring when the toggle is tabbed to is the platform's own native focus appearance. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

