
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Path | string | none (required) | The member's full dotted path (e.g. `"vscode.languages.onDidChangeDiagnostics"`); used only in refusal messages and log lines, per its own doc comment. |
| Delay | time interval (seconds) | none (required) | The window's width in seconds; each event member picks its own — `0.050` for `vscode.languages.onDidChangeDiagnostics`. |
| Window scheduler | window-scheduling seam | none (required, no default) | The window-scheduling seam; production callers pass the timer-backed scheduler, tests pass a recording double. |
| Merge function | function from a list of payloads to one payload | none (required) | Collapses one window's queued payloads into one merged payload; `vscode.languages.onDidChangeDiagnostics` passes a flattening function. |
| Map function | function from (payload, JavaScript context) to an optional JavaScript value | none (required) | Builds the JavaScript value a listener in a given context receives from the merged payload; returning nothing skips that context's listeners for the delivery. |
| (subscribe call) `thisArgs` | second call argument | unbound | Bound as the listener's `this` only when JavaScript-truthy, per **this-args-truthy-gate**. |
| (subscribe call) `disposables` | third call argument | none | When a JavaScript array, receives the returned `Disposable` via `push`, per **disposable-pushed-to-array-argument**. |

