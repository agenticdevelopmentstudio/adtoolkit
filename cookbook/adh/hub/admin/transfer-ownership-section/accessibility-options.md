
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no transition, animation, or motion effect is defined by this section; any open/close motion belongs to the composed disclosure/dialog/dropdown-menu components, out of scope here. |
| Increase Contrast | Not applicable: the component uses only semantic color theme roles (text, muted text, gold) and defines no raw color or opacity-based color of its own that would need a distinct high-contrast variant. |
| Differentiate Without Color | Resolved: every state that carries meaning pairs color with text or an icon, never color alone — the token-revocation warning pairs a warning glyph with count text, the current/disabled item appends the text "(current)" rather than relying on a muted color, and the Transfer action's non-destructive nature is conveyed by its "Transfer" label, not by the `warning` variant's color alone (`warning` is itself a color treatment, per `transfer-button-not-destructive-styled`). |

