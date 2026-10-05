
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; each radio button's selected state reflects whether its paired choice value equals the view model's value. |
| Selected (per button) | On, drawn as the platform's system filled-radio-dot appearance; set on init, on a user click that changes the value, and on any external change-notification that resolves to that choice. |
| Unselected (per button) | Off, drawn as the platform's system empty-radio-circle appearance; set on init and re-synced for every button whose paired value does not equal the view model's value. |
| Pressed | Not styled by this component; the platform's own mouse-down/press visual for a radio-type button is its default rendering, not custom to this component. |
| Disabled | Not implemented in this component; the enabled state is never read or set on the label or any radio button in source. A caller may set an individual button's enabled state directly (the array elements are mutable references even though the array property itself is read-only from outside), at which point the platform's native disabled dimming applies to that one button. |
| Focused | Not styled by this component; any focus ring when a button is tabbed to is the platform's own native focus appearance. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

