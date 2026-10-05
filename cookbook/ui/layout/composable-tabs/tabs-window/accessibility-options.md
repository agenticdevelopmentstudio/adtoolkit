
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the window performs no animated transitions of its own; tab installation, arrangement mirroring, and drawer open/close are owned by the tabbed content view and the window drawer, each a separate ingredient. |
| Increase Contrast | Not applicable: chrome colors are sourced from the shared theme palette; contrast handling is a design-system-level concern this window does not decide. |
| Differentiate Without Color | Handled: the help toggle differentiates open/closed by symbol shape (outline vs. filled question-mark glyph) and tooltip text, not by tint alone; the arrange toggle differentiates on/off by the button's own pressed/active visual state, in addition to tint. |

