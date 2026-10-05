
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none defined in source) | `Pause` | Pause button's initial title, and its title whenever the paused flag is `false`. |
| (none defined in source) | `Resume` | Pause button's title whenever the paused flag is `true`. |
| (none defined in source) | `Clear` | Clear button's title, a literal string. |
| (none defined in source) | `Connected` | Status label text/tooltip when the connected flag is `true`. |
| (none defined in source) | `Connecting…` | Status label text/tooltip when the connected flag is `false` and no last-error value is set. |

`Pause`, `Resume`, `Clear`, `Connected`, and `Connecting…` are all assigned
as plain string literals directly to the button's title or the label's
displayed text, not through a localization-key mechanism, so the component
is unlocalized as written: it defines no string-key scheme, and wiring one
in is the host app's localization owner's responsibility. (The last-error
string is displayed as-is and is excluded from this table: its content and
any localization are the injected controller implementation's concern, not
the component's.)

