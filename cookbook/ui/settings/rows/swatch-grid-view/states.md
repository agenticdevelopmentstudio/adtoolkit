
| State | Appearance change |
|-------|------------------|
| Default | Swatches render in rows per colors/columns; empty colors renders zero rows. |
| Pressed | Not applicable: no interactive control or click-handling code exists anywhere in source; swatches and rows are plain, non-interactive elements. |
| Disabled | Not applicable: an enabled state is never referenced in source; the component has no notion of an enabled/disabled state. |
| Focused | Not applicable: the component overrides no focus-related property and contains no interactive control, so it never becomes first responder or shows a focus ring. |
| Loading | Not applicable: every operation in source (rebuilding, swatch creation, color replacement) is a synchronous property assignment; there is no asynchronous operation and no loading indicator. |

