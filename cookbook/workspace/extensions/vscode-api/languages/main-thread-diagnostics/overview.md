
This component gives extension code the `vscode.languages` diagnostics
slice: `createDiagnosticCollection`, `getDiagnostics`, and the debounced
`onDidChangeDiagnostics` event (`vscode.d.ts`, `:14807`, `:14814`). It is
two cooperating parts. The diagnostic store (holding only plain values —
a URL and a diagnostic value, never a script value) is the storage layer:
it owns collection lifecycle (creating and removing a collection),
per-collection mutation (`set`, `setEntries`, `delete`, `clear`),
per-collection reads (`get`, `has`, `pairs`), and cross-collection reads
(diagnostics for one `Uri`, and all diagnostics). This component is the
extension-facing adaptor built on top of it: it validates and decodes
every argument arriving from extension code, builds the extension-visible
`DiagnosticCollection` object each `createDiagnosticCollection` call
returns, and publishes the shared, debounced `onDidChangeDiagnostics`
emitter. Every mutating operation reports the URLs it touched to an
injected diagnostic sink; the sink, not this adaptor, fires the event —
the host diagnostic sink is the production conformer, and its own
documentation explains why the event's read half (`onDidChangeDiagnostics`,
published here) and write half (reporting changed URLs, called here but
implemented in the sink) sit on opposite sides of that seam. This
component ports upstream VS Code's own diagnostics implementation
closely, including two upstream quirks it keeps rather than "fixes" (the
array-set overload's stable-sort-by-`Uri`-string cleanup asymmetry, and
`clear()`/`dispose()` not firing on an already-empty collection under an
earlier reading — see Design Decisions), and diverges from it in one
place it states plainly: a disposed collection's methods are inert no-ops
rather than throwing, with precedent cited from this codebase's own
status-bar-item handling.

