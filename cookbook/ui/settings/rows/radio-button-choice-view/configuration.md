
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `viewModel` | choice view model | — (required) | Supplies the row's title, the ordered choices list, and the current value; receives committed radio-button changes. The initializer also overwrites this view model's change-notification callback with the component's own sync handler (see Edge Cases). A choice's optional symbol-image field is accepted by the type but never read by this component (see Overview). |
| `axis` | layout orientation | vertical | Sets the controls group's orientation and, through a vertical/non-vertical branch, its alignment. Has no effect on the outer [label, controls group] group, which is always vertical. |

