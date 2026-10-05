
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the view performs no animation or transition; text assignment is a synchronous property set. |
| Increase Contrast | The view sets no custom color of its own — its coloring comes entirely from the theme's `.secondaryText` role — and nothing in the view or the theme's color derivation observes or reacts to the system's Increase Contrast setting; the color choice is unconditional. Whether the resulting per-theme contrast is sufficient at all is **minimum-contrast-ratio** and its Design Decision, not duplicated here. |
| Differentiate Without Color | Not applicable — the view conveys no state through color at all; it renders only the caller-supplied text in a single, fixed secondary-text color, with no color-coded meaning to differentiate. |

