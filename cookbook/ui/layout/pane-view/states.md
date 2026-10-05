
| State | Appearance change |
|-------|------------------|
| Default | — |
| Pressed | Not applicable: the pane container itself has no pressed state; its close/minimize/zoom buttons, the gear, and the spacing control and its reset button each have their own recipe and their own pressed appearance. |
| Disabled | Not applicable as a whole-pane state; the close and minimize controls are independently enabled or disabled per their own close/minimize availability — see Behavioral Requirements. |
| Focused | Not applicable as a visual state of this concept; the pane draws no focus ring of its own. |
| Loading | Not applicable: any loading indicator belongs to the hosted content, which has its own recipe. |
| Whole | Title bar over content; both held the content inset off the container's edges. |
| Minimized (top/bottom) | Content and its container are hidden; the title bar stays visible, and its minimize control shows a restore glyph (a plus icon) and tooltip "Restore Pane". |
| Minimized (leading/trailing) | Title bar and content are hidden; a minimized rail is docked to that edge, showing the content's glyph and tooltip or the generic defaults. |
| Zoomed | The zoom control's glyph and tooltip flip (an expand icon ↔ a contract icon, "Zoom Pane" ↔ "Unzoom Pane"); the pane's own size and position are unaffected by this concept — resizing is the host's responsibility. |
| Clamped to container | The title bar, every view already inside it, and any chrome installed into it afterward carries the lowest layout priority for horizontal compression resistance (value `1`), so the pane never forces its container wider. |

