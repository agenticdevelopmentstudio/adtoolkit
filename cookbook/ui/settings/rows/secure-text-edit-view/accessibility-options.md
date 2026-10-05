
| Option | Behavior |
|--------|----------|
| Reduce Motion | Inherited unmodified from the text edit row — source contains no animation or transition call in either file; every state change is an instantaneous property assignment. |
| Increase Contrast | Inherited unmodified from the text edit row — text/label color comes from the theme's `primaryText`/`placeholderText` roles, whose actual resolved contrast (including the placeholder role's 1.6:1 floor — see **contrast-ratio** in Compliance below) is the theme layer's responsibility, not this component's. |
| Differentiate Without Color | Inherited unmodified from the text edit row; also not applicable on its own terms here — masking is communicated by replacing characters with the system's dot glyphs, not by color, so there is no color-only signal for this component to provide an alternative to. |

