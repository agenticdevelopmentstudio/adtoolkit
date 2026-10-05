
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this component's own source contains no animation or transition call of any kind; every title and checkmark update is an instantaneous property assignment. |
| Increase Contrast | Not applicable: the file sets no custom color beyond the foreground tint color, sourced from the active theme's `primaryText` role; the pull-down's bezel/border chrome is the platform's native rendering, which follows the system's Increase Contrast setting automatically. |
| Differentiate Without Color | Supported: selection state is communicated through the built-in checkmark glyph on each menu item, not through a color-only signal introduced by this component, so no separate path is needed. |

