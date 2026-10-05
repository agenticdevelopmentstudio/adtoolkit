
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `Show details` | Disclosure control's tooltip and accessibility label when constructed `isCollapsed: true` |
| (none — hardcoded literal) | `Hide details` | Disclosure control's tooltip and accessibility label when constructed `isCollapsed: false` |

`title`, `subtitle`, `summary`'s `name`/`value` strings,
`status.accessibilityLabel`, and `titleTrailingStatus.accessibilityLabel`
are all caller-supplied at the call site — the
component defines no string literals of its own for them. The two disclosure
strings above ARE component-owned literals, and the source assigns them
directly (`"Show details"`/`"Hide details"`) with no localization key or
string-catalog entry — a real localization gap for a component intended to
ship in a localized app, documented here rather than smoothed over.

