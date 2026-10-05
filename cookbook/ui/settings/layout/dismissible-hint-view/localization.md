
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (no key; literal default parameter value) | "Got It" | `buttonTitle`'s default value when a caller constructs the component without supplying one |

`buttonTitle`'s default value, the English literal `"Got It"`, carries no
localization key or lookup — `text` and any explicit `buttonTitle`
argument are the caller's responsibility to localize (the same treatment
as the sibling Badge recipe (`adtoolkit://cookbook/ui/controls/badge`)
gives fully caller-supplied text), but this one default value ships baked
directly into the component itself; a call site that never overrides
`buttonTitle` ships this English literal regardless of the app's locale.

