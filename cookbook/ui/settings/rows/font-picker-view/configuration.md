
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | font view model object | - (required) | Supplies the row's title and current font; receives committed font picks. The initializer also overwrites this view model's external-change handler with the component's own resync handler (see Edge Cases). |
| `isEnabled` | boolean | `true` | Dims and disables the row's button and label when set to `false` (see **dims-and-disables-the-row**). |

