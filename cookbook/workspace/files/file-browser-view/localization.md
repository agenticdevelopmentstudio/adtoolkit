
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none defined in source) | `Add a directory to this project` | Add control's tooltip. |
| (none defined in source) | `Add` | Directory picker's confirm-action label. |
| (none defined in source) | `Choose directories to show in this project's file browser.` | Directory picker's message. |
| (none defined in source) | `Remove "<name>" from this project` | Remove control's tooltip when enabled; `<name>` is the selected root's last path component. |
| (none defined in source) | `Select an added directory to remove it` | Remove control's tooltip when disabled. |

All five user-facing strings above are assigned directly as literal text
rather than through any localization key or lookup mechanism, so these are
genuinely unlocalized; no string-key scheme is defined for this component
(see Platform Notes for why). (A failure-trap message naming the primary
root's path is a programmer-error trap surfaced only in a crash log, not
user-facing text, and is excluded from this table.)

