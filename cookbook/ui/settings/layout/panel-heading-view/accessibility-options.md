
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the source performs no animation or transition of any kind; construction is a synchronous sequence of view and layout setup. |
| Increase Contrast | Not applicable to this component directly — the source sets no custom color and reads no system contrast setting. The title label's color is the theme's primary-text role, applied unconditionally across this whole system, not something this component computes or could get wrong independently of the palette it draws from. The caption's secondary-text role carries the open question already tracked in the Explanation View recipe; it is not repeated here. |
| Differentiate Without Color | Not applicable — the component conveys no state through color at all; it renders the caller-supplied title (and optional caption) in two fixed, fixed-role colors, with no color-coded meaning to differentiate. |

