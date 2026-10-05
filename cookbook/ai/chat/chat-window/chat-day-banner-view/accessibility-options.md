
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the view has no animation or transition; the label and rules are laid out once at init and only recolor on theme change, which is a static style change, not a motion effect. |
| Increase Contrast | Not applicable in this file: colors come entirely from the active `SemanticPalette` (`.timestampText`, `.divider`); if Increase Contrast should raise these colors' contrast, that is the palette's responsibility, not this view's. |
| Differentiate Without Color | Not applicable: the banner conveys a single day value through text alone; it has no state or category communicated through color that would need a non-color alternative. |

