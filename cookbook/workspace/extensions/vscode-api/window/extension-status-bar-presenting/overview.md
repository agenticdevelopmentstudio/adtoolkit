
This component is the presenter seam behind `vscode.window.createStatusBarItem`:
the interface the extension-host bridge above this contract calls into
whenever a returned `StatusBarItem` object's `show()`, `hide()`, or
`dispose()` method runs, or one of its mutable property setters commits a
change. It was split out of that bridge's own source, which had grown past
2,800 lines, as a file-boundary reorganization rather than a tier
boundary — the bridge remains its only caller. The same component also
declares the two data types its two operations pass across that seam:
`ExtensionStatusBarAlignment` (VS Code's `StatusBarAlignment` enum, reduced
to `left`/`right`) and `ExtensionStatusBarItemRequest` (one
`createStatusBarItem()` call's current display state, reduced to what a
presenter needs to render it). The contract carries no rendering logic and
no state of its own; the production conformer renders every shown item into
the trailing slot of each open window's footer bar, and the test suite
exercises the contract through a recording double.

