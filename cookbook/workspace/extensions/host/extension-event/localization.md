
Subscribing's two refusal messages are hardcoded English string literals with no localization key or platform localization mechanism: `"<path> requires a listener function."` and `"<path> could not create a Disposable in context '<context name>'."` Both reach the extension as a thrown JavaScript error, so an extension author sees the literal English text regardless of locale. The three error messages logged during delivery are likewise hardcoded English, but those reach only the host's own log, never the extension.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `<path> requires a listener function.` | Raised when subscribing's first argument fails the function-type check. |
| (none — literal only) | `<path> could not create a Disposable in context '<context name>'.` | Raised when the shared disposable-creation helper returns nothing. |

