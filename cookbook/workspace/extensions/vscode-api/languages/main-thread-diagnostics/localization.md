
- **hardcoded-error-messages**: every error message this component raises — `"createDiagnosticCollection requires a string name, or no argument."`, `"getDiagnostics requires a Uri, or no argument."`, `"Could not decode a diagnostic for this Uri."`, `"Could not decode a diagnostic entry."`, `"Invalid entries passed to DiagnosticCollection.set."`, `"DiagnosticCollection.set requires a Uri, an entries array, or no argument."`, `"Invalid diagnostics array passed to DiagnosticCollection.set."`, `"DiagnosticCollection.delete requires a Uri."`, `"DiagnosticCollection.get requires a Uri."`, `"DiagnosticCollection.has requires a Uri."`, `"DiagnosticCollection.forEach requires a callback function."`, `"DiagnosticCollection.forEach could not decode the Uri of an entry."`, `"DiagnosticCollection.forEach could not decode a diagnostic for this Uri."`, and `"DiagnosticCollection.forEach could not invoke its callback."` — are hardcoded English string literals with no localization key or mechanism. They are visible to the extension author that made the mistake, not to the app's own end-user UI.
- **hardcoded-log-strings**: this component logs nothing directly at these call sites; the one logging event a call into this component's decode paths can trigger — a message noting an array longer than the maximum this host decodes — is a hardcoded, unlocalized message declared in the shared decoding helper every extension-bridge component uses, including this one.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `createDiagnosticCollection requires a string name, or no argument.` | Raised when the first argument is present, not a string, and not `undefined`/`null`. |
| (none — literal only) | `getDiagnostics requires a Uri, or no argument.` | Raised when a present, non-`null` first argument does not decode as a `Uri`. |
| (none — literal only) | `Could not decode a diagnostic for this Uri.` | Raised by the resource branch of `getDiagnostics` and by `get`, when a stored diagnostic fails to re-encode. |
| (none — literal only) | `Could not decode a diagnostic entry.` | Raised by the no-argument branch of `getDiagnostics` and by the pairs-encoding step, when a stored pair fails to re-encode. |
| (none — literal only) | `Invalid entries passed to DiagnosticCollection.set.` | Raised when the array-taking overload's argument contains an undecodable tuple. |
| (none — literal only) | `DiagnosticCollection.set requires a Uri, an entries array, or no argument.` | Raised when the first argument is truthy, not an array, and not a `Uri`. |
| (none — literal only) | `Invalid diagnostics array passed to DiagnosticCollection.set.` | Raised when the single-`Uri` overload's second argument is present but not decodable. |
| (none — literal only) | `DiagnosticCollection.delete requires a Uri.` | Raised on a missing/undecodable first argument to `delete`. |
| (none — literal only) | `DiagnosticCollection.get requires a Uri.` | Raised on a missing/undecodable first argument to `get`. |
| (none — literal only) | `DiagnosticCollection.has requires a Uri.` | Raised on a missing/undecodable first argument to `has`. |
| (none — literal only) | `DiagnosticCollection.forEach requires a callback function.` | Raised when the first argument to `forEach` is not callable. |
| (none — literal only) | `DiagnosticCollection.forEach could not decode the Uri of an entry.` | Raised when an entry's stored `Uri` fails to re-encode during `forEach`. |
| (none — literal only) | `DiagnosticCollection.forEach could not decode a diagnostic for this Uri.` | Raised when an entry's diagnostics fail to re-encode during `forEach`. |
| (none — literal only) | `DiagnosticCollection.forEach could not invoke its callback.` | Raised when the callback cannot be invoked. |
| (none — literal only) | `refusing an array of <count> elements: longer than the 100000 this host decodes` | Logged inside the shared array-length helper every extension-bridge component uses, not inside this component; reached whenever this component decodes a diagnostics array. |

