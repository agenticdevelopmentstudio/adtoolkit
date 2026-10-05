
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | choice view model object | — (required) | Supplies the row's title, the ordered choice list, and the current value; receives committed slider changes via its setting observer. The initializer also overwrites this view model's external-change handler with the component's own selection-sync handler (see Edge Cases). Each choice's optional image identifier is accepted by the type but never read by this component (see Overview). |

