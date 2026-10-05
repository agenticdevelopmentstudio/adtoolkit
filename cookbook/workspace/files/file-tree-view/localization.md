
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none defined) | `Scanning…` | Placeholder row text while a root manager is syncing, a literal string. |
| (none defined) | `Empty` | Placeholder row text for a root with no contents, a literal string. |
| (none defined) | `Open` | Context menu item title, a literal string. |
| (none defined) | `Open in a New Tab` | Context menu item title, a literal string. |
| (none defined) | `Open to the Side` | Context menu item title, a literal string. |
| (none defined) | `Reveal in Finder` | Context menu item title, a literal string. |
| (none defined) | `Copy Path` | Context menu item title, a literal string. |
| (none defined) | `Folder` | Icon accessibility description for a directory, a literal string. |
| (none defined) | `File` | Icon accessibility description for a file, a literal string. |
| (none defined) | `Unsaved changes` | Unsaved-changes marker accessibility description, a literal string. |

All ten strings above are assigned directly as literal values to their
respective UI elements rather than through any localization key or lookup
call (see Platform Notes for the exact APIs used on Apple platforms, and why
this component's platform does not get the automatic localization-key
treatment some others do). No string-key scheme exists for this component.
File and directory names themselves are user data, not chrome text, and are
correctly excluded from this table.

