
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | view model | — (required) | Supplies the row's title and current value; receives committed field changes. The initializer overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases). |
| `minimum` | number (same type as the field) or none | none | The lowest value the field will store. No minimum clamps nothing at the bottom. |
| `maximum` | number (same type as the field) or none | none | The highest value the field will store. No maximum clamps nothing at the top. |
| `fieldWidth` | number (points) | `72` | Width of the number field, in points. |
| `labelWidth` | number (points) or none | none | When set, pins the label to a fixed, right-aligned width so a column of rows lines up; when not set, the row spans the container's full width. |

