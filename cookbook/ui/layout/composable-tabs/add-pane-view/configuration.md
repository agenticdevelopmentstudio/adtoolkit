
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `choices` | list of offerable entries | — (required) | The offerable views, in display order; empty disables OK and leaves the "Add" choice list empty. |
| `onAdd` | callback (view identifier, direction) → none | — (required) | Invoked once, after dismissal, when OK is activated with a valid selection. |

Each offerable entry (not a top-level configuration option itself) carries
three fields: a view identifier, a display name (the choice item's title),
and an optional icon name shown as that item's image.

