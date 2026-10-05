
This component's configuration inputs:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | text/rich content | — (required) | Uppercase-mono caption above the control |
| `prefix` | string | — (required) | Fixed, inherited prefix shown as static text before the input (e.g. `app.my-eco.`); `""` edits the whole value |
| `value` | string | — (required) | The editable leaf when `prefix` is set, or the whole rdid when `prefix` is `""` |
| `onChange` | callback taking the next string | — (required) | Called with the lowercased next value |
| `placeholder` | string | none | Native input placeholder |
| `hint` | text/rich content | none | Footnote text shown when there is no `error` |
| `error` | text/rich content | none | Inline error, shown in the footnote in place of `hint` |
| `disabled` | boolean | none | Disables the input |
| `id` | string | generated automatically | Input identifier, and the target of the label's association |

