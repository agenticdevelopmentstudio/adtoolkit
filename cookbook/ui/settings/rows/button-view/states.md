
| State | Appearance change |
|-------|------------------|
| Default | The button displays the view model's `title` in the platform's default bezel style; no custom styling from the component. |
| Pressed | Not styled by the component; any pressed visual is the button's own native press feedback. |
| Disabled | Not implemented by the component; the source never reads or sets the button's enabled state. A caller may set it directly through the public button property, at which point the platform button's native disabled dimming applies. |
| Focused | Not styled by the component; any focus ring is the button's own native focus appearance. |
| Loading | Not applicable: the component performs no asynchronous work of its own and defines no loading state. |

