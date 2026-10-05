
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this file animates nothing of its own — the hover fill and selection border are set as instantaneous property writes on the row's own background, not as animated transitions. The embedded typing indicator's own animation is that component's concern; see `adtoolkit://cookbook/ai/chat/chat-window/typing-indicator-view`. |
| Increase Contrast | Not implemented in source: this view sets no independent high-contrast styling. All colors (`.selection`, `.timestampText`, `.danger`) are read from the active `SemanticPalette`; whatever contrast increase that palette provides on request is inherited automatically, and this file does nothing further. |
| Differentiate Without Color | Selection is differentiated by shape (a border), not color alone (see Accessibility, "Color dependence"); hover is differentiated by color alone, with no accompanying shape or icon change — the source provides no alternative cue for hover. |

