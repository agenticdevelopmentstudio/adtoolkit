
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this file performs no animation of any kind (not even an opacity fade) — the help icon swap is an instantaneous image/tint/tooltip change with no transition to reduce. |
| Increase Contrast | Not applicable: every color used here is read from the shared theme palette; contrast handling is a design-system-level concern this file defers to that shared, separately-recipe'd system. |
| Differentiate Without Color | Handled: the help toggle differentiates open/closed by icon shape (outline vs. filled question-mark icon) and by tooltip text, not by tint alone (see **shows-filled-glyph-when-drawer-open** and **swaps-help-tooltip-by-drawer-state**). |

