
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `delegate` | Delegate reference (optional, held weakly) | None | Receives tab lifecycle callbacks: new-tab request, select, active-tab change, close request, reorder. |
| `mainContentViewController` | Content reference (optional) | None | Shown in the shared content area while no tab is active. |
| `contentInsets` | Insets (top/left/bottom/right, points) | All zero | Gap held between the mounted content and the tab bars/edges around it. |
| `centerBackgroundColor` | Color (optional) | None | Overrides the shared content area's fill; unset falls back to the `windowBackground` role. |
| `centerOutlineColor` | Color (optional) | None | Overrides the shared content area's `1pt` border color; unset falls back to the palette's `outline` role. |
| Tab start inset | Number (points) per edge | `8` | Where a bar's first tab begins, measured along the bar from its start. |
| Edge enabled state | Boolean per edge | `true` for the top edge; `false` for the right/bottom/left edges | Whether an edge's tab bar and tabs are shown at all. |

