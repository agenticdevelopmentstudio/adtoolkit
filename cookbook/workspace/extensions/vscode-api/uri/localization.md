
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, not externalized) | `Uri.parse: '{value}' must contain a scheme when 'strict' is true` | The `Error.message` `Uri.parse(value, true)` throws when `value` carries no scheme, with `{value}` substituted by the value's string form (**parse-strict-requires-scheme**). |
| (none — literal, not externalized) | `Uri.joinPath: the base argument must be a vscode.Uri` | The `TypeError.message` `Uri.joinPath` throws when `base` is not a `Uri` instance (**join-path-requires-uri-instance**). |

Both are hardcoded English literals with no localization mechanism (no string catalog, no key lookup) anywhere in this component; see the `no-hardcoded-strings` row in Compliance.

