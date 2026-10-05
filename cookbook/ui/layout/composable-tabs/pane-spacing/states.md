
| State | Appearance change |
|-------|------------------|
| Default — hairline gutter (divider thickness ≤ 1pt) | The platform's own default hairline divider paint. |
| Default — wide gutter (divider thickness > 1pt) | Divider area filled with the theme's pane-backdrop color. |
| Pressed | Not applicable: dragging a divider is the platform's own built-in split-view behavior; this component paints no pressed/highlighted state of its own. |
| Disabled | Not applicable: neither the pane spacing settings nor the split view expose a disabled state; a `0`-point gutter is a valid, still-draggable style choice (see minimum-divider-grab-fixed), not a disabled divider. |
| Focused | Not applicable: no focus ring or focus-driven appearance change appears in this component. |
| Loading | Not applicable: all six settings are read synchronously from local storage; this component has no async operation and no loading state. |

