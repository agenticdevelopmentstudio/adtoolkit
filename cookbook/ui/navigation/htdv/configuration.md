
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Data source (supplied when constructing the controller) | An object implementing the data-source contract | none - required | The tree the controller navigates; the host supplies its own implementation. |
| Change callback (property on the controller) | A callback receiving the controller | Does nothing | Callback fired after every state transition; single-slot, not multicast. |
| Rail width (property on the layout engine) | A width | `240` | Width budgeted per rail column when deciding how many fit. |
| Reserved detail width (property on the layout engine) | A width | `480` | Width reserved for the detail pane, subtracted from the available width when a detail is shown. |
| Sections, actions (parameters when constructing a form specification) | A list of sections, and the form's actions | none - required / no actions set | The form's fields grouped into sections, and its save/delete/extra actions. |
| Initial values (parameter when constructing the form model) | A set of field values keyed by field | Empty | Initial field values; any field absent here falls back to its own default value. |
| Requires changes (property on the form model) | A boolean | `true` | Whether the form can be saved requires the form to be dirty; a create dialog sets this to `false`. |
| Blocked reason (property on the form model) | An optional message | none | When set, disables saving and is shown as the reason (e.g. a read-only member). |
| Change callback (property on the form model) | A callback receiving the form model | Does nothing | Callback fired after every state transition; single-slot, not multicast. |
| Locale (parameter to validation) | A locale | The current locale | Locale used to format numeric bounds quoted in validation messages. |
| Pattern, pattern message (fields on a text field) | An optional regular expression, and an optional custom message | none, none | An optional whole-value-anchored regular expression and its custom failure message. |
| Minimum, maximum, requires integer (fields on a number field) | Optional numbers, and a boolean | none, none, `false` | Inclusive numeric bounds and whether a non-integral value is rejected. |

No settings-key or environment-variable constants appear anywhere in this
scope: nothing here reads an environment variable or a named settings key.
Every field kind's own configuration is supplied programmatically by the
caller building the form specification, not read from a store.

