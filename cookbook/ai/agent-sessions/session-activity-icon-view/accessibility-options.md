
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the rotation (working's spin) and the opacity pulse (waiting/summarizing) both repeat indefinitely, and nothing in this component checks the platform's Reduce Motion signal before starting either, nor is a static substitute offered for either animated state. |
| Increase Contrast | Not applicable to this component directly: the source reads no system contrast setting; the tint always comes from the active theme (or the system fallback color before the first theme apply), so whether the resulting contrast is adequate is tracked once under **theme-owned-tint-contrast** above and its Design Decision, not duplicated here. |
| Differentiate Without Color | Supported: each state's glyph shape (double-arrow, filled dot, circled exclamation mark, sparkle) differs from every other state's shape independently of the tint color a theme assigns (see **state-based-symbol-selection** and **state-based-tint**), so state is never conveyed by color alone. |

