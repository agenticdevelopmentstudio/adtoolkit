
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition call appears in either file; every state change (init, sync, commit) is an instantaneous property assignment. |
| Increase Contrast | Not applicable: neither file sets a custom color outside the theme's primaryText role; the text field's own default border/bezel rendering already tracks the system's Increase Contrast setting automatically. |
| Differentiate Without Color | Not applicable: the component conveys no state through color alone — valid, invalid, and clamped values are communicated entirely through the displayed digits; an invalid entry reverts silently with no color-only error indicator in source. |

