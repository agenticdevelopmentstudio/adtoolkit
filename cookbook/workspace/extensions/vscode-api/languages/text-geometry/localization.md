
- **hardcoded-thrown-error-messages**: `Position`'s constructor throws the English literals `'line must be non-negative'` and `'character must be non-negative'`; a `null` argument to `translate`/`with` on either `Position` or `Range` throws the fallback literal `'Illegal argument'`; `Range`'s constructor throws `'Invalid arguments'`; `Location`'s constructor throws `'Illegal argument'` directly. None of these carries a localization key — they are visible to the extension author whose code triggered the throw, not to the app's own end-user UI.
- **hardcoded-log-strings**: the three logged error messages from installation (an evaluate failure, an `installedError` failure, and a missing container member) are hardcoded English interpolated strings with no localization key.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `line must be non-negative` | `Position`'s constructor, thrown for a negative `line`. |
| (none — literal only) | `character must be non-negative` | `Position`'s constructor, thrown for a negative `character`. |
| (none — literal only) | `Illegal argument` | `translate`/`with`'s `null`-argument check on `Position` and `Range`, and `Location`'s constructor for a second argument that is neither position-like nor range-like. |
| (none — literal only) | `Invalid arguments` | `Range`'s constructor, thrown when neither the four-number nor the two-position form matches. |
| (none — literal only) | `Could not install the 'vscode.Position'/'vscode.Range'/'vscode.Location' classes in context '<name>'; they stay the shim's not-implemented stub` | Logged when evaluating the class-defining source returns nothing or a non-object. |
| (none — literal only) | `Could not install the 'vscode.Position'/'vscode.Range'/'vscode.Location' classes in context '<name>': '<message>'; they stay the shim's not-implemented stub` | Logged when the evaluated result carries an `installedError`. |
| (none — literal only) | `The 'vscode' text-geometry container in context '<name>' is missing 'Position', 'Range' or 'Location'; all three stay the shim's not-implemented stub` | Logged when the resolved container is missing an expected member. |

