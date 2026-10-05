
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the component performs no animation or transition; the path, caption, and label are all assigned once, synchronously, at construction. |
| Increase Contrast | Not applicable to this component directly — it sets no custom color; its coloring comes entirely from the theme's `.secondaryText` role. Whether the resulting per-theme contrast is sufficient is tracked once under Accessibility above, not duplicated here — see the open question on minimum-contrast-ratio there. |
| Differentiate Without Color | Not applicable — the view conveys no state through color at all; it renders only the path (and an optional caption) in a single, fixed secondary-text color, with no color-coded meaning to differentiate. |

