
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component performs no animation or transition anywhere — every state change (theme colors, fonts, the width floor) is an instantaneous property or constraint-constant assignment. |
| Increase Contrast | Not applicable to this component directly: the source reads no system contrast setting; every color it draws comes from the active `SemanticPalette`, and whether the resulting contrast is sufficient is tracked once under Accessibility above, not duplicated here. |
| Differentiate Without Color | Satisfied: the disclosure state is communicated by the control's own orientation plus its tooltip/label text, not color; the status badge and the title status symbol each pair their tint with a symbol icon shape and an `accessibilityLabel`; and every summary value is always paired with its `name` text label (`formats-summary-parts`) rather than color alone. |

