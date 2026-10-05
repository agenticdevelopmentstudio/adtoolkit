
This component is the seam a `vscode.window.show*Message` call is reduced
to before any presentation-layer specifics get involved. It defines three
things: `ExtensionMessageSeverity`, an enumeration for which of the three
`show*Message` calls (`showInformationMessage`, `showWarningMessage`,
`showErrorMessage`) produced the request; `ExtensionMessageRequest`, a
value carrying everything a presenter needs to show something and report
back which button — if any — the user chose; and the presenting contract
itself, constrained to reference-type conformers, with one method,
`presentMessage(_:)`, that presents a request and asynchronously produces
an optional button index. The one production conformer given among the
sources presents a request as a modal alert; this recipe documents the
contract that conformer (and any other) must satisfy, not that
conformer's own presentation choices, except where the request's own
documentation describes an invariant a conformer is required to honor.

