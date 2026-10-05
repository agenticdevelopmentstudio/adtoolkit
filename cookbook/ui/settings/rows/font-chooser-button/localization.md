
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `System` | The button's initial title, set unconditionally at construction, before any caller-supplied title is applied. |

`"System"` is a title assignment from a string literal — an unlocalized
literal — and no localization key or string-catalog mechanism wraps it
anywhere in this file. Every other title the button ever shows is
caller-supplied, so localizing that text is the caller's responsibility,
not this component's; only the one built-in `"System"` default is this
component's own literal, and it is not wrapped in any localization
mechanism — a caller that never gives the button its own title sees this
hardcoded English text regardless of the system's locale.

