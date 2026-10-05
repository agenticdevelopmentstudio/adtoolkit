
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition call appears in source; every state change (init, sync, commit) is an instantaneous property assignment. |
| Increase Contrast | Not applicable: source sets no custom color on the stepper; the labels' colors come from the theme's primaryText/secondaryText roles, and the stepper's own bezel rendering follows the system's Increase Contrast setting automatically. |
| Differentiate Without Color | Not applicable: the component conveys no state through color alone — the current value is shown as digits in the value label. Reaching a bound stops further movement (see disables-stepper-wraparound) rather than wrapping, but nothing in source shows the stepper rendering an arrow as disabled at the minimum/maximum; it only absorbs the click. The component introduces no color-only cue of its own either way. |

