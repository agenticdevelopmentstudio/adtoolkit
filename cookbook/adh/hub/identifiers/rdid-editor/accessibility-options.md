
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source contains no transition, animation, or motion of any kind — every state change (invalid marker, disabled, focus ring) is an instant state swap. |
| Increase Contrast | Not applicable to this component directly: contrast is governed entirely by the shared color/typography token theme used by the field shell and caption style; the editor implements no separate high-contrast behavior of its own (the open token-contrast question is tracked once, under Accessibility above). |
| Differentiate Without Color | Satisfied: the invalid state is carried by the error text itself (**shows-error-in-place-of-hint**) and by the invalid marker, not by a color change alone. |

