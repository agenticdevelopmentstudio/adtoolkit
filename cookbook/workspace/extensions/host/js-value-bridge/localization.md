
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, not externalized) | `{path} is unavailable: this extension's host has been torn down.` | The `Error.message` rejecting for a torn-down host builds (via rejecting with an error), delivered to an extension's `Promise.catch` as `error.message`, with `{path}` substituted verbatim by the caller's `path` argument. |

This is a hardcoded English literal with no localization mechanism (no string catalog, no key lookup) anywhere in the source; see **reject-torn-down-wording** and the `no-hardcoded-strings` row in Compliance.

