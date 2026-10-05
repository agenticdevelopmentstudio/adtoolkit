
The state emits one hardcoded, untranslated English message pattern that consumers display to the user (the dashboard view renders it after `Failed to load status — `):

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; inline literal) | `status <code>` | Thrown error message when an error response carries no usable `error` detail; `<code>` is the numeric HTTP status. |

The backend-supplied `error` string is passed through untranslated.

