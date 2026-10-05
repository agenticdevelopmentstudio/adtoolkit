
- **hardcoded-error-messages**: The three `TypeError` messages this component's constructors throw — `"location must be a vscode.Location"`, `"range must be a vscode.Range"`, and `"message must be set"` — are hardcoded English string literals with no localization key. They are visible to the extension author, not to the app's own end-user UI, per the component's own documentation framing these as validation surfaced to "the extension" that made the mistake.
- **hardcoded-log-strings**: The three error-log messages produced while installing the diagnostic types (evaluate failure, script-side installed-error, missing container member) are hardcoded English log strings, also unlocalized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `location must be a vscode.Location` | `DiagnosticRelatedInformation`'s constructor, thrown when `location` fails the `instanceof` check. |
| (none — literal only) | `range must be a vscode.Range` | `Diagnostic`'s constructor, thrown when `range` fails the `instanceof` check. |
| (none — literal only) | `message must be set` | `Diagnostic`'s constructor, thrown when `message` is falsy. |
| (none — literal only) | `Could not install the 'vscode.DiagnosticSeverity'/'vscode.DiagnosticTag'/'vscode.DiagnosticRelatedInformation'/'vscode.Diagnostic' classes in context '<name>'; they stay the shim's not-implemented stub` | Logged while installing the diagnostic types, on an evaluate failure. |
| (none — literal only) | `Could not install the 'vscode.DiagnosticSeverity'/'vscode.DiagnosticTag'/'vscode.DiagnosticRelatedInformation'/'vscode.Diagnostic' classes in context '<name>': '<error>'; they stay the shim's not-implemented stub` | Logged while installing the diagnostic types, on a script-side installed-error. |
| (none — literal only) | `The 'vscode' diagnostic-types container in context '<name>' is missing one of 'DiagnosticSeverity', 'DiagnosticTag', 'DiagnosticRelatedInformation' or 'Diagnostic'; all four stay the shim's not-implemented stub` | Logged while installing the diagnostic types, when the container is missing an expected member. |

