
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `colors` | array of colors | `[]` | The colors displayed, laid out row-major into fixed-width rows of `columns` swatches each. |
| `columns` | integer | `8` | Maximum swatches per row; clamped to a minimum of 1 (`clamps-column-count`). |
| `swatchSize` | size (width/height) | 22 by 22 | Fixed width/height applied to every swatch via layout constraints. |
| `spacing` | number | `4` | Applied uniformly as both the inter-row (vertical) gap and the inter-swatch (horizontal) gap within a row. |

