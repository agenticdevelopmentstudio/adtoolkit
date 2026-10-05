
Subsystem: the app's own bundle identifier (falling back to `"nil"`) | Category: the shared extension-host logger (declared once and reused by every ingredient in this area, including this one)

| Event | Level | Message |
|-------|-------|---------|
| Evaluating the class-defining source returns nothing or a non-object | error | `Could not install the 'vscode.Position'/'vscode.Range'/'vscode.Location' classes in context '<name>'; they stay the shim's not-implemented stub` |
| The evaluated result carries a non-empty `installedError` | error | `Could not install the 'vscode.Position'/'vscode.Range'/'vscode.Location' classes in context '<name>': '<message>'; they stay the shim's not-implemented stub` |
| The resolved container is missing `Position`, `Range`, or `Location` | error | `The 'vscode' text-geometry container in context '<name>' is missing 'Position', 'Range' or 'Location'; all three stay the shim's not-implemented stub` |

No other event in this ingredient is logged: the failed cache-write inside the class-defining source is caught and silently ignored (per **cache-write-optional**), and building a position, range, or location value each clear a construction-time exception without logging it (per their respective **-clears-exception-on-throw** requirements).

