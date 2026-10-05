
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: source performs no animation or transition call anywhere — every visibility and state change is an instantaneous property assignment, not even an opacity fade. |
| Increase Contrast | Not implemented in source: this file sets no independent high-contrast styling of its own. The title and status labels' colors are theme role tokens (primaryText, secondaryText, success, danger) resolved by the active theme palette; whatever Increase Contrast adjustment that palette makes is inherited automatically and is that theming system's concern, not this file's. The toggle's on/off rendering is the platform's own, which tracks Increase Contrast natively. |
| Differentiate Without Color | Satisfied without a color-only signal: the status label's *text* changes with availability (`"available"`, `"unavailable — <reason>"`, `"press a key combination"`, or the refusal sentence) in addition to its color role, so availability is never communicated by color alone. |

