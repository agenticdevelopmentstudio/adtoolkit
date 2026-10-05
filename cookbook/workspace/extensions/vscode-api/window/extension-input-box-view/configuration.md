
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | `ExtensionInputBoxModel` | — (required, set at construction) | Supplies `request.title`/`prompt`/`placeHolder`/`isPassword`/`valueSelection`, the current `value`, and validation state. Read once for the field's kind at construction; read again once the view loads to seed content; read continuously via `model.value`/`canAccept`/`isValidating` for the lifetime of the panel. |
| `onAccept` | callback taking the accepted value | no-op | Called with `model.value` when Return is accepted (see `model-gated-acceptance`/`acceptance-deferral`). |
| `onCancel` | callback taking no arguments | no-op | Called when Escape is pressed (see `escape-cancellation`). |
| `onValueChanged` | callback taking the current value | no-op | Called with the field's new value whenever it needs (re)validating — on every edit and once for the pre-filled value (see `value-commit-and-revalidation`/`prefill-validation-once`). |

