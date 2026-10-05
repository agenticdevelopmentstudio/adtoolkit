
| State | Appearance change |
|-------|------------------|
| Default | Lines, grid, axes drawn; no tooltip |
| Single series | No legend |
| Two or more series | Legend below the plot, one plain-line icon and label per series |
| Hovered x position | Crosshair line in the border token and a tooltip listing every series at that x |
| Null value | Break in that series' line |
| Disabled | Not applicable: the chart has no interactive control to disable; its interaction is pointer hover (and the chart library's default arrow-key navigation). |
| Pressed | Not applicable: the chart has no pressable element. |
| Loading | Not applicable: the source has no async operation or loading flag; the caller supplies points synchronously. |
| Error | A series list longer than four raises a range error instead of rendering (see refuses-fifth-series). |

