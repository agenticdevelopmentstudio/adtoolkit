
Document which accessibility display options this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: every content swap is an immediate add/remove of the child view; no animation context, layer animation, or transition appears anywhere in this component. |
| Increase Contrast | Not observed in this file: the container's fill color is resolved through the theme system's semantic palette lookup (its `.surface` role), so any contrast adaptation belongs to the theme system, out of this ingredient's scope. |
| Differentiate Without Color | Not applicable: this component draws no state that is distinguished by color alone — its only color use is a single background fill, with no second state it must be told apart from by anything else. |

