
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component performs no animation or transition; every state change (label/text sync, theme restyle, commit) is an instantaneous property assignment. |
| Increase Contrast | Not applicable to this component directly: it sets no literal color; text/background color come from the theme's primary-text/control-background/selection/cursor roles, whose actual resolved contrast is the theme layer's responsibility, not this component's. |
| Differentiate Without Color | Not applicable: the component conveys no state through color alone — selection is communicated by the standard highlighted-background text-selection affordance common to all text editors, not by a color-only signal distinguishing otherwise-identical content. |

