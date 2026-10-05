
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | range view model object | — (required) | Supplies the row's title and min/max/current value; receives committed slider changes via its setting observer. The initializer also overwrites this view model's external-change handler with the component's own sync handler (see Edge Cases). |
| `formatter` | a value-to-text formatting function | — (required) | Maps the current or in-progress slider value to the caption text shown at the trailing edge of the row (e.g. a percentage or seconds string). |

