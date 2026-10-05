
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source contains no animation. The toggle's icon/label swap and every layout change happen instantly. |
| Increase Contrast | Not implemented directly in this component: it always renders whatever color the palette resolves for a given role. The palette's dimmed text roles (`secondaryText`, `timestampText`) do enforce a minimum contrast floor against the window background, but nothing in this file or the palette verifies contrast between a bubble's own paired fill and text color (e.g. `userText` against `userBubble`) — that pairing is only as good as the active theme's own choices. |
| Differentiate Without Color | Not implemented in source. In `.speaker` style, role is told apart by fill/text/border color alone, with no icon, label, or positional cue from this component. In `.terminal` style the two conversational roles are made to look identical on purpose (see **terminal-style-role-fill-override**), so there is no color distinction to differentiate from in the first place. |

