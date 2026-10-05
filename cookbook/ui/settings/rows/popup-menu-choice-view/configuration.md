
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | choice view model | — (required) | Supplies the row's title, ordered choices (each a label/value/optional symbol name), and current value; receives committed selection changes. The initializer also overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases and **replaces-onchange-handler**). An inherited `explanation` field is accepted by the initializer chain but is unsupported: this component never reads or displays it. |

