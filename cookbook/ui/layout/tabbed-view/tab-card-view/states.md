
| State | Appearance change |
|-------|------------------|
| Default (depth `1`, before any caller sets it) | Behind — same as the "Behind, horizontal edge" or "Behind, vertical edge" row below, whichever edge this card is on. |
| Front (depth `0`) | Background = `projectPaneBackdrop`, border = `projectPaneOutline`, agent label = `.accent`, session label = `.primaryText`, the other three labels and the close tint = `.secondaryText`; painted background overhangs the workspace-facing side by `1pt`; text inset at depth `0` is `0` — only the paint overhangs. |
| Behind, horizontal edge (depth > 0, top/bottom) | Background = `windowBackground`, border = `border`, agent label = `.primaryText`, the rest and the close tint = `.tertiaryText`; card and text pulled in `4pt` on every side, flat regardless of depth. |
| Behind, vertical edge (depth 1–3, left/right) | Same palette as "Behind" above; card and text pulled in `4pt` per step of depth, up to `12pt` at depth `3` and beyond, so deeper cards read visibly smaller and further back. |
| Depth transition (card on screen) | The recolor/reposition above animates over `0.16s` with an ease-out curve rather than jumping; off-screen it jumps. |
| Pressed | Not applicable: the component defines no mouse-tracking behavior and no pressed appearance; a click is the hosting item's concern (documented in the tabbed-view recipe), not this component's. |
| Disabled | Not applicable: no disabled state, tint, or appearance is defined anywhere; a tab card that exists is always drawn at full strength. |
| Focused | Not applicable: no custom focus-ring or focused appearance is defined; the close control's focus indicator is left at the platform default, and no other element declares itself keyboard-focusable. |
| Loading | Not applicable: every operation in this component (updating status symbols, content updates, depth changes) is synchronous; no loading/pending indicator is defined. |

