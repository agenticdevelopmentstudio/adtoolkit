
Document which accessibility display options this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: every visual transition in this component (the placeholder-to-tree swap, a reload, the message banner's show/hide) is an immediate view/constraint change; no animation context or animated transition appears anywhere in this component. |
| Increase Contrast | Not observed in this component: every color is a semantic token resolved by the theme system (`.surface`, `.primaryText`, `.secondaryText`, `.tertiaryText`, `.divider`); any contrast adaptation belongs to that theme system, out of this recipe's scope. |
| Differentiate Without Color | Not applicable: this component draws no state — selected, expanded, timed-out, or otherwise — using color as the sole distinguishing cue. Text roles differ in weight and size (body vs. caption text scale), not color alone, and selection/expansion are drawn by the tree's own default chrome rather than a custom color-only cue defined in this component. |

