
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | range view model (double-valued) | — (required) | Supplies the row's title and min/max/current value; receives committed slider changes via its value. The initializer also overwrites this view model's change-notification callback with the component's own re-sync handler (see Edge Cases). |

