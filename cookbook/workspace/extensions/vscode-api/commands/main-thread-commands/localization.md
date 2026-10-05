
This adaptor raises or rejects with hardcoded English string literals; none carries a localization key or catalog entry. Every raised or rejected message reaches the extension as a thrown or rejected error, so an extension author sees the literal English text regardless of locale. The two log-only messages the invoke operation produces (a caller-less rejection or throw) reach only the host's own log, never the extension. The registry's two error messages are not literals in this adaptor, but handling an execute-command call passes them through to the extension verbatim, so they are user-facing text this component is responsible for surfacing.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `registerCommand requires a string command id.` | Raised when `registerCommand`'s first argument is missing or not a string. |
| (none — literal only) | `registerCommand requires a callback function.` | Raised when `registerCommand`'s second argument is missing. |
| (none — literal only) | `registerCommand's callback must be a function.` | Raised when `registerCommand`'s second argument fails the function-type check. |
| (none — literal only) | `command '<id>' already exists` | Raised when this adaptor already owns `<id>`. |
| (none — literal only) | `executeCommand requires a string command id.` | Rejected when `executeCommand`'s first argument is missing or not a string. |
| (none — literal only) | `The extension host could not install its command dispatch trampoline in JavaScript context '<context name>', so extension command callbacks cannot be invoked in it.` | Raised by `registerCommand` or rejected by `executeCommand` when dispatch is unavailable. |
| (none — literal only, from the registry's own error description) | `No command is registered with id '<id>'` | Rejected by `executeCommand` when the registry's execute operation throws its unknown-command error. |
| (none — literal only, from the registry's own error description) | `Command '<id>' is registered but currently disabled` | Rejected by `executeCommand` when the registry's execute operation throws its disabled-command error. |

