
Subsystem: the app's own bundle identifier | Category: the bridge

| Event | Level | Message |
|-------|-------|---------|
| Installing the class failed | error | `Could not install the 'vscode.Uri' class in context '<name(of: context)>'; it stays the shim's not-implemented stub` |

This is the one logging call this component makes (**class-install-failure-returns-nil-and-logs**); no other member writes to the log, and reading a URL or building a Uri value return nothing on every failure path with no log call of their own.

