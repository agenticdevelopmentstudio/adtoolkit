
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | bounded range view model (integer-valued) | — (required) | Supplies the row's title, min/max bounds, and current integer value; receives committed stepper changes via its value. The initializer overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases). |

