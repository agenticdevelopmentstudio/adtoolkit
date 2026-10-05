
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | boolean view model object | — (required) | Supplies the row's title and current boolean value; receives committed toggle changes via its setting observer. The initializer also overwrites this view model's external-change handler with the component's own update handler (see **claims-sole-onchange-observer**). An inherited explanation field is accepted by the initializer chain but never read or rendered anywhere in source. |

