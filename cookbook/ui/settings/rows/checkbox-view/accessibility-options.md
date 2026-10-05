
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: source contains no animation or transition call; every state change is an instantaneous property assignment. |
| Increase Contrast | Not verified for the label: this component sets no custom color of its own on the toggle, and the label's color comes from the theme's primaryText color role, but nothing in this source, or in the theme code searched, shows that role responding to the system Increase Contrast setting. The toggle's own track/thumb colors are unmodified system rendering, which does track Increase Contrast automatically. |
| Differentiate Without Color | Not applicable: the on/off state is communicated through the toggle's own track position and system iconography, not through a color-only signal introduced by this component. |

