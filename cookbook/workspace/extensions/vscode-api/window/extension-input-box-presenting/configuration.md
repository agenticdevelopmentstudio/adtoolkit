
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | optional text | none (optional) | Label shown above the field, or absent. |
| `prompt` | optional text | none (optional) | Text shown underneath the field, or absent. |
| `placeHolder` | optional text | none (optional) | Placeholder text, or absent. |
| `value` | text | empty string | The pre-fill text — never absent. |
| `valueSelection` | optional integer range | absent (whole value selected) | Reduced to user-perceived-character offsets; an empty range positions the cursor only. |
| `isPassword` | boolean flag | false | Whether the field masks its content. |
| `ignoreFocusOut` | boolean flag | false | Whether losing focus dismisses the box. |
| `isValidating` | boolean flag | false | Whether the originating call supplied a validation function at all. |
| `validate` | async function from text to an optional validation result | none (required parameter of the presentation) | Runs the call's validation, if any; always answers an absent result when the validating flag is false. |

