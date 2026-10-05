
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | range view model object | — (required) | Supplies the row's title and min/max/current integer value; receives committed field changes via the view model's setting observer. The initializer overwrites this view model's external-change handler with the wrapped field's own sync handler (see Edge Cases). |
| `fieldWidth` | numeric (points) | `52` | Width of the number field, in points. Differs from the wrapped view's own uncalled default of `72` — see Design Decisions. |
| `labelWidth` | numeric (points), optional | `nil` | When set, pins the label to a fixed, right-aligned width so a column of rows lines up; when unset, the row spans the container's full width. |

