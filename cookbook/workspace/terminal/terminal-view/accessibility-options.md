
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the caret's border-width/border-color and caret-color/caret-text-color changes are instantaneous property assignments with no animation, transition, or movement code in source. |
| Increase Contrast | Not applicable from within this file: this view performs no color computation of its own — the caret color/text color are applied verbatim from whatever the caller supplies (see the pending contrast decision under Design Decisions). |
| Differentiate Without Color | Supported: the active-pane indication conveyed by the marks-active-pane flag is the caret's *shape* — filled block versus hollow outline — not its color alone, per source: "A full block, which also says which pane the user is working in: filled here, an outline in every other pane." |

