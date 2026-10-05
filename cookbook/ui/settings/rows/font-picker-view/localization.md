
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none - hardcoded literal fragments) | `" — %@ pt"` / `" (not installed)"` | Built by a private helper and given as the button's title on every resync. |

The label's text comes from the view model's title, a value the caller
provides, so there is nothing for this component to localize there. The
`" — "`, `" pt"`, and `" (not installed)"` fragments inside that private
helper, however, are hardcoded English string-interpolation literals
assigned to the button's title (a plain string) - not wrapped in any
localization mechanism anywhere in source.

