
Document which accessibility display options this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no animation or transition occurs anywhere in this component; every state change (filtering, highlighting, checking) is an instantaneous property assignment or table reload. |
| Increase Contrast | Not applicable to this component directly: no custom color is ever set here; every color comes from a color role resolved by the active theme, so Increase Contrast support is the active theme's responsibility, not this component's. |
| Differentiate Without Color | Partial: the checked state itself is communicated solely by the checkbox's own on/off checkmark glyph — no color-only signal there. But the *highlighted* row (arrow-key focus) is shown only by the table row's own selection-role fill (a 4pt-corner-radius, 2pt/1pt-inset rounded rect — see **States** › Focused); this component draws no separate icon, border, or text-weight change alongside that fill, so whether the highlight is distinguishable without color depends entirely on that fill's contrast against the row's normal background. |

