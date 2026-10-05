
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component contains no animation or transition of its own; every preview refresh is an instantaneous call, which itself redraws by removing and re-adding its contents rather than animating. |
| Increase Contrast | Not applicable: the component sets no custom color of its own; all coloring belongs to the composed choice control and preview, each of which tracks the active theme (and, transitively, system contrast) through its own concept. |
| Differentiate Without Color | Not applicable: the component conveys no state through color; the only state it introduces (which theme is active) is communicated through the control's selected item text and the preview's full rendered sample, not a color-only signal added by this component. |

