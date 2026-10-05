
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. The depth-driven recession/overhang move animates whenever the card's view has a window, with no check of the system's Reduce Motion setting anywhere in this component. Because this is a positional/size animation - a slide of the card's paint and text inset, not an opacity-only cross-fade - it falls outside the fade exemption, and the move animates unconditionally whenever the view has a window, regardless of the Reduce Motion setting. |
| Increase Contrast | Not applicable: the component draws only theme-resolved semantic colors (`.primaryText`, `.secondaryText`, `.tertiaryText`, `.accent`, `.border`, `.windowBackground`, `.projectPaneBackdrop`, `.projectPaneOutline`) obtained from the resolved theme's palette; any Increase Contrast adaptation of those values is the palette resolver's responsibility, not a branch this component takes itself. |
| Differentiate Without Color | Supported. A card behind the front one is not distinguished by color alone: it is also drawn measurably smaller and pulled back from the workspace edge, so size and position remain as independent, non-color cues to which card is selected. |

