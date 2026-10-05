
| State | Appearance change |
|-------|------------------|
| Default | The internal stack is empty and pinned inside the panel; the background is already painted from the current theme at construction. |
| Group added | A group view is appended as the next arranged child, separated from the previous arranged child (if any) by the default 20pt group-spacing value. |
| Heading added, stack previously non-empty | A panel heading view is appended; the gap between it and the arranged child before it is widened to 30pt; its width is matched to the internal stack. |
| Heading added, stack previously empty | A panel heading view is appended as the first arranged child; no spacing adjustment is made because there is no predecessor. |
| Theme changed | The background is reassigned to the new theme's window-background role; no other visual property changes. |
| Pressed | Not applicable: the source defines no target/action or gesture recognizer of its own; it is a passive layout host. |
| Disabled | Not implemented in the source; an enabled/disabled state is never read or set anywhere in source. |
| Focused | Not applicable: the view never becomes key/first responder; the source overrides no responder-chain behavior. |
| Loading | Not applicable: the source performs no asynchronous operation and defines no loading indicator. |

