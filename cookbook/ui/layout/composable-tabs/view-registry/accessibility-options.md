
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the placeholder's tint and layout are set once, synchronously, with no animation or transition; there is no motion for this setting to reduce. |
| Increase Contrast | Not applicable as a distinct code path: the source performs no Increase-Contrast-specific branching of its own; all color comes from theme tokens whose actual values live outside this file (see Accessibility > Contrast). |
| Differentiate Without Color | Satisfied without a marker: each placeholder's identity is not conveyed by tint color alone — its title label always shows the pane's number, which is the primary identifying cue; the color tint is a secondary reinforcement, per **placeholder-pane-number** and **placeholder-series-tint**. |

