
- **hardcoded-error-messages**: the two JavaScript error messages this component raises — `setLanguageConfiguration requires a string language id.` and the `wordPattern` empty-match refusal (`Invalid language configuration: wordPattern '<pattern>' is not allowed to match the empty string.`) — are hardcoded English string literals with no localization key or lookup call. Both are visible to the extension author whose call triggered them, not to the app's own end-user UI.
- **hardcoded-teardown-message**: the torn-down message both members can produce (`"<path> is unavailable: this extension's host has been torn down."`, built by the shared member-installation helper, not by this component directly) is likewise hardcoded English, surfaced through this component's `getLanguages` rejection and `setLanguageConfiguration` exception.
- **hardcoded-log-string**: the one error-level log message in the word-pattern refusal check (a `wordPattern` that fails to compile) is a hardcoded English interpolated log string, also unlocalized.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal only) | `setLanguageConfiguration requires a string language id.` | Raised when the first argument to `setLanguageConfiguration` is missing or not a string. |
| (none — literal only) | `Invalid language configuration: wordPattern '/pattern/flags' is not allowed to match the empty string.` | Raised when a non-exempt `wordPattern` compiles and matches the empty string. |
| (none — literal only) | `vscode.languages.getLanguages is unavailable: this extension's host has been torn down.` | Shared member-installation teardown helper, produced when `getLanguages` reaches a torn-down instance of this component. |
| (none — literal only) | `vscode.languages.setLanguageConfiguration is unavailable: this extension's host has been torn down.` | Shared member-installation teardown helper, produced when `setLanguageConfiguration` reaches a torn-down instance of this component. |
| (none — literal only) | `wordPattern '/pattern/flags' does not compile under the platform's regex engine (<error>); stored unvalidated rather than refused, per Ruling 12` | Logged when the pattern fails to compile. |

