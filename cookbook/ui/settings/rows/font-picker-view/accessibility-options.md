
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: source contains no animation or transition call anywhere; the enabled-state dimming (button state / label opacity) is an instantaneous property assignment, not an animated transition. |
| Increase Contrast | Not applicable to this file directly: source reads no system contrast setting and sets no custom color; the label's coloring comes from the active theme's primaryText role (tracks Increase Contrast automatically) and the button's title color is the platform's own default control rendering. Whether the 40%-opacity disabled dimming remains sufficiently contrasted is tracked once under Accessibility above (the open question on minimum-contrast-ratio), not duplicated here. |
| Differentiate Without Color | Not applicable: the component conveys no state through color alone; the enabled state is communicated through both the button's own interactive appearance (not merely a color) and the label's opacity, and the font name/installed-status is communicated through text, not color. |

