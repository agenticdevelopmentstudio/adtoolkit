
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: source contains no animation, transition, movement, or scaling; every appearance change is an instantaneous property assignment. |
| Increase Contrast | Not applicable to this component directly: this component's own source reads no system contrast setting, and neither does the `SemanticPalette` color-resolution path it calls into; whether the resulting colors are contrasty enough is tracked once, under the open question on minimum-contrast-ratio in Accessibility above, not duplicated here. |
| Differentiate Without Color | During the "prior shortcut still showing" transition, the border color changing from `borderColor` to `accentColor` is the only indicator that recording has begun; no icon, text, or shape change accompanies it until a chord is captured, unlike every other state, where the text itself changes. The component does not respond to Differentiate Without Color. |

