
`MainThreadWindow` is the adaptor, confined to the UI thread, that answers everything
an extension reaches for on `vscode.window`'s message, quick-pick, input-box
and status-bar surface: `showInformationMessage`, `showWarningMessage`,
`showErrorMessage`, `showQuickPick`, `showInputBox` and
`createStatusBarItem`. It is not a UI component itself — it holds no view,
draws nothing, and has no appearance. Every call it receives from the
embedded JavaScript engine is parsed, coerced and validated against the
extension's actual arguments, then handed to one of four injected presenter
protocols (`ExtensionMessagePresenting`, `ExtensionQuickPickPresenting`,
`ExtensionInputBoxPresenting`, `ExtensionStatusBarPresenting`) that do the
real presenting; this recipe documents the adaptor's own contract —
argument parsing, coercion, promise settlement, status-bar item bookkeeping
and teardown — not the four presenter protocols' own contracts, which each
already have their own recipe. A fifth collaborator, `NotImplementedLedger`,
receives a record whenever a status-bar item's `tooltip` or `command` is set
to a shape this host does not project (a `MarkdownString`-typed tooltip or a
`Command`-object-typed command).

The type is not safe to share across threads and is confined to the UI thread by design: every member
it exposes is called from the script engine's synchronous bridge, which itself
only ever calls in from the UI thread, so there is no cross-thread hop to
document. It conforms to `Loggable` but, as of this source, none of its
members call through the logger — every failure this adaptor detects is
reported to the extension itself, by rejecting or never settling the promise
it returned, not by a log line.

