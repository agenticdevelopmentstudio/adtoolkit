
Subsystem: the host application's bundle identifier (falling back to a default when unavailable) | Category: the shared logger for this extension-API area, reused across every component in it, including this one

| Event | Level | Message |
|-------|-------|---------|
| Evaluating the diagnostic-classes source in the context returns an empty value or a non-object | error | `Could not install the 'vscode.DiagnosticSeverity'/'vscode.DiagnosticTag'/'vscode.DiagnosticRelatedInformation'/'vscode.Diagnostic' classes in context '<name>'; they stay the shim's not-implemented stub` |
| The evaluated result carries a non-empty installed-error value | error | `Could not install the 'vscode.DiagnosticSeverity'/'vscode.DiagnosticTag'/'vscode.DiagnosticRelatedInformation'/'vscode.Diagnostic' classes in context '<name>': '<installedError>'; they stay the shim's not-implemented stub` |
| The installed container is missing one of the four expected members | error | `The 'vscode' diagnostic-types container in context '<name>' is missing one of 'DiagnosticSeverity', 'DiagnosticTag', 'DiagnosticRelatedInformation' or 'Diagnostic'; all four stay the shim's not-implemented stub` |
| An array passed to the shared array-length check (via decoding a related-information array or a tags array) reports a length over 100,000 | error | (logged inside the shared array-length check, not inside this component): `refusing an array of <count> elements: longer than the 100000 this host decodes` |

No other event in this component is logged: neither a constructor's error nor a decode failure for a malformed field is logged at the point it occurs — both are facts the code surfaces to the caller (as a thrown script error, or as a decode failure) instead of a log line, per **diagnostic-constructor-validates-range**/**diagnostic-constructor-validates-message** and **diagnostic-decode-optional-field-malformed-refuses-whole-value**.

