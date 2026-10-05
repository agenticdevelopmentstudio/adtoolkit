
| State | Appearance change |
|-------|------------------|
| Default | The group container, card, card row, and divider render exactly the static appearance described above; there is no other visual state for any of them. The search field shows the wrapped control's placeholder or current text. |
| Pressed | Not applicable: none of the six pieces wires a target/action, gesture recognizer, or tap handler of its own. The search field's clear button and magnifier icon are the native control's own chrome. |
| Disabled | Not applicable: an enabled/disabled state is never read or set on any of the six pieces. |
| Focused | Not applicable for the group container, card, card row, and divider, which accept no keyboard focus. For the search field, no custom focus styling is applied — wrapping a genuine native search control means the system supplies the native focus ring automatically, the explicit reason this vocabulary does not hand-roll the control (see Design Decisions). |
| Loading | Not applicable: none of the six pieces performs asynchronous work or defines a loading indicator. |

