
None of the user-facing strings this file introduces route
through a localization mechanism — each is a string literal or string
interpolation written directly in source. The command's title itself is a
caller-supplied value (populated by whatever feature declares the command
descriptor) and is out of this file's scope, matching how sibling
settings-row recipes treat a caller-supplied title. No localization key
exists for any of these literals; the table below lists them as proposed
keys, not keys present in source. The `"available"` / `"unavailable"`
availability labels shown in the status label come from the shared
availability model, not from this file, and so are not listed below.

| Proposed String Key | Literal (en) | Context |
|-----------|-------------|---------|
| `key_command_row.title_format` | `"<title>:"` (trailing colon appended to `command.title`) | Title label text |
| `key_command_row.placeholder.click_to_record` | `Click to record` | Capture field placeholder when unbound |
| `key_command_row.status.press_a_key_combination` | `press a key combination` | Status label when a pending chord has not yet been captured |
| `key_command_row.status.refusal_prefix` | `can't switch on — ` | Prefix before the availability reason when a toggle-on attempt is refused |
| `key_command_row.status.reason_separator` | ` — ` | Separator concatenated between the availability label and its reason |

