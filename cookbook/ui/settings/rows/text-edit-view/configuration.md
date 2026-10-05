
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | View model | — (required) | Supplies the row's title and current string value; receives committed edits. The initializer also overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases). An explanation field the view model may carry is accepted but never read or displayed by this component. |

