
| State | Appearance change |
|-------|------------------|
| Default | The header and the card are added to the outer stack; the row area starts empty until a row is added — no rows, no separators. |
| Row added (standard style) | A row is appended with 9pt padding above and below its content and 14pt padding on each side; whether it also shows a leading hairline is decided separately by the separator-visibility rule. |
| Row added (continuation style) | A row is appended with 0pt top padding (tucked against the row above) and the same 9pt bottom / 14pt horizontal padding; it never shows a separator. |
| Separator shown | A standard-style row with a not-hidden predecessor: the divider is visible, separator band height = 1pt, inset 14pt from the leading edge. |
| Separator collapsed | The first row in the card, any continuation-style row, or a standard-style row with no not-hidden predecessor: the divider is hidden, separator band height = 0pt. |
| Row content hidden | A row's own hidden state mirrors its content's hidden state; the layout omits its space, and the separator-visibility rule may then collapse the separator on the row that follows it. |
| Pressed | Not applicable: the component, the card, and each row define no target/action and receive no press interaction of their own — any pressed styling belongs to a row's caller-supplied content. |
| Disabled | Not implemented in this component; an enabled/disabled state is never read or set anywhere. |
| Focused | Not styled by this component; any focus ring belongs to a row's own content, not to the container. |
| Loading | Not applicable: the component performs no asynchronous operation and shows no loading indicator. |

