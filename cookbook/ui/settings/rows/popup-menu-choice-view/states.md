
| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; the popup's selected item matches the choice whose value equals the view model's value, if one exists. |
| Menu Open | Not styled by this component; the popup's own native menu presentation (item list, chevron pair) when clicked — not custom in source. |
| Item Selected | The item the user clicks becomes the popup's selected item; the component's internal handler then commits its associated value to the view model per **commits-selection-value**, **ignores-unresolvable-selection**, and **skips-redundant-commits**. |
| Pressed | Not applicable: the component renders no button of its own; the popup's own press/active bezel-less appearance while its menu is open is the platform's default rendering, not custom to this component. |
| Disabled | Not implemented in this component; the enabled state is never read or set on either control in source. A caller may set the popup's enabled state directly through the public popup property, at which point the platform's native disabled dimming applies. |
| Focused | Not styled by this component; any focus ring when the popup is tabbed to is the popup's own native focus appearance. |
| Loading | Not applicable: the component has no asynchronous operation and no loading indicator in source. |

