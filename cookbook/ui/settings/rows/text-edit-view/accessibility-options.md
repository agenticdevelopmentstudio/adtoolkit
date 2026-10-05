
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component performs no animation or transition; every state change is an instantaneous property assignment (the label's text, the field's value, the field's font/color). |
| Increase Contrast | Not applicable to this component directly: it sets no literal color; text/label color comes from the theme's primary-text/placeholder-text roles, whose actual resolved contrast (including the placeholder role's 1.6:1 floor — see Design Decisions and the Accessibility section's Contrast note) is the theme layer's responsibility, not this component's; the text field's bezel/border follow the platform's own default rendering. |
| Differentiate Without Color | Not applicable: the field's content is the plain typed text itself; no state in this component is communicated by color alone. |

