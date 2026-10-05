
- **Data collected**: this component reads only manifest-declared display metadata — extension identifier, view id, name, icon reference (a codicon name or a relative file path string, never opened), `when` clause text, `visibility`, and `initialSize`. It never reads, stores, or transmits a credential, token, or user-content value.
- **Storage**: this component writes nothing to disk or to any persistent store; it returns its result to the caller, which decides what to keep (a separate registry component, outside this file's scope).
- **Transmission**: this component performs no network communication.
- **Retention**: the returned containers, views, and notes lists exist only as values the caller holds; this component itself retains nothing between calls.

