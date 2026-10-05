
| Option | Behavior |
|--------|----------|
| Reduce Motion | Delegated: this component's only motion is the typing indicator, which it starts animating while the session state is `.responding` and stops otherwise. Whether that pulse honors Reduce Motion is the typing indicator's own behavior and is specified in adtoolkit://cookbook/ai/chat/chat-window/typing-indicator-view; this component adds no animation of its own. |
| Increase Contrast | Not applicable in this file: every color comes from the active theme palette (`.primaryText`, `.secondaryText`, `.placeholderText`, `.accent`, `.divider`, `.chatSurface`); if Increase Contrast should raise these colors' contrast, that is the palette's responsibility, not this component's. |
| Differentiate Without Color | Supported: a message's role is conveyed by horizontal position — right-aligned for `.user`, left-aligned for `.assistant`/`.error`, centered for `.notice` (see **role-differentiated-by-position**) — in addition to whatever color the bubble fill itself uses, so role remains legible without relying on color alone. |

