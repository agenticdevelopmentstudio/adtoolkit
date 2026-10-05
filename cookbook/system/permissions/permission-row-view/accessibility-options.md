
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: this component performs no animation of any kind — every state change (the status label's text, the status dot's color, the action button's title) is an instantaneous property assignment. There is no explicit animation call anywhere in source for Reduce Motion to affect. |
| Increase Contrast | The status dot, status label, and action-button title color use semantic dynamic colors (the success color, the warning color, the secondary label color) that adjust automatically under Increase Contrast, but the card's fixed background/border colors do not, and the component does not respond to Increase Contrast for them. |
| Differentiate Without Color | Grant status is always communicated by the status dot's color together with the status label's text (`Granted` / `Not Granted` / `Unknown`) and the action button's title — never by color alone — so no additional adjustment is required. |


