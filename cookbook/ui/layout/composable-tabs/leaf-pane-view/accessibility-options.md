
Document which accessibility display options this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: overlay install/removal and content dim/undim are immediate view add/remove operations; no animation context, layer animation, or transition appears anywhere in this file. |
| Increase Contrast | Not observed in this file: pane border and fill colors are resolved through the theme system's semantic-role lookup (e.g. the `projectActivePaneOutline` role), so any contrast adaptation belongs to the theme system, out of this ingredient's scope. |
| Differentiate Without Color | Not implemented: the active/inactive distinction is carried by border color alone (`projectActivePaneOutline` vs. `projectPaneOutline`; see the **active-pane-cue-is-color-only** requirement), with no accompanying change in border width, shape, or label, and the source never queries the platform's differentiate-without-color accessibility setting. |

