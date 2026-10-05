
- **Data collected**: this component collects no data of its own; it stores and re-encodes whatever `Uri`, `Diagnostic` (range, message, severity, source, code, relatedInformation, tags), and collection-name values an extension supplies through `vscode.languages` calls, without retaining a copy beyond the diagnostic store's own in-memory state for the lifetime of the collections that hold them.
- **Storage**: all state lives in the diagnostic store's in-memory state; nothing in this component persists to disk or any other durable store.
- **Transmission**: this component makes no network call; it neither sends nor receives anything over a network.
- **Retention**: a collection's diagnostics are retained only until that collection's own `dispose()` or the owning adaptor's disposal removes it from the store; nothing here retains data beyond that lifetime, and a torn-down adaptor's collections are actively removed rather than merely dereferenced.

