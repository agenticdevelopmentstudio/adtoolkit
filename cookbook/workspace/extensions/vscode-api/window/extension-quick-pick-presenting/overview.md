
This component declares the extension-host's contract for one
`vscode.window.showQuickPick` call: two data types,
`ExtensionQuickPickItem` and `ExtensionQuickPickRequest`, that reduce a
`QuickPickItem`/`QuickPickOptions` call to what a presenter needs, and
the presenting contract, `ExtensionQuickPickPresenting`, that a presenter
conforms to in order to actually put a picker on screen (or, in a test,
record what it was asked to show). The production conformer among the
given implementations also conforms to the sibling input-box presenting
contract, one panel serving both seams. The presenting contract is
declared separately from the message-presenting contract, deliberately,
on an interface-segregation rationale (see Design Decisions).

