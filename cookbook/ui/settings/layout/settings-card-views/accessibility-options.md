
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: none of the six pieces applies an animation, transition, or motion effect of its own — every one is built once from static layout, with no looping effect anywhere. |
| Increase Contrast | Applies, but is not handled here: the group container's caption reuses the secondary-text role (3.0 minimum-contrast floor) and 11pt caption size that the sibling header component's caption also uses — the open question about raising that floor for Increase Contrast is tracked in that component's own recipe and not re-raised here. The divider's own role (10% blend, no stated minimum-contrast floor) raises the same open question independently — see **minimum-contrast-ratio** and its Design Decision. |
| Differentiate Without Color | Not applicable: none of the six pieces conveys state or meaning through color alone — each renders exactly one presentation, with no color-coded distinction for an alternate cue to replace. |

