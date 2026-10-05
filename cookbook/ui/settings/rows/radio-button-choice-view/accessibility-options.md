
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — source contains no animation or transition call; every state change is an instantaneous property assignment (the label's text, a button's selected state). |
| Increase Contrast | Not applicable — this component sets no custom color of its own on any radio button; the heading label's color comes from the theme's `.primaryText` role, and each radio button's dot/track colors follow the platform's default rendering, which tracks the system's Increase Contrast setting automatically. |
| Differentiate Without Color | Not applicable — the selected choice is communicated through the platform's own filled-vs-empty radio-dot iconography and each button's own visible title text, not through a color-only signal introduced by this component. |

