
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component contains no animation or transition; every layout change (adding a row, toggling separator visibility, hiding a row) is an instantaneous assignment. |
| Increase Contrast | Not applicable to this component directly: it reads no system contrast setting; the card's fill and the divider's color are theme-resolved semantic roles (`.elevatedSurface`, `.divider`), neither of which this component adjusts for contrast itself. |
| Differentiate Without Color | Not applicable: the component conveys grouping and row separation through structure — padding and a hairline — not through color alone; whether a row shows a divider is driven by its layout effect, never by a color-only cue. |

