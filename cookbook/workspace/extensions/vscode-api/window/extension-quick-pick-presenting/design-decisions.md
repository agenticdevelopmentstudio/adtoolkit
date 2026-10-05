
**Decision**: `ExtensionQuickPickPresenting` is a separate protocol from `ExtensionMessagePresenting`, rather than one protocol carrying both members.
**Rationale**: per the source's own doc comment, `NSAlertMessagePresenter` is the right conformer for a message and the wrong one for a picker; a single combined protocol would force a message-only conformer to implement a presentation it has no business showing — interface segregation, at the declared cost that `MainThreadWindow.init` takes two presenters rather than one.
**Approved**: pending

**Decision**: `nil` means the picker was dismissed; `[]` (only reachable when `canPickMany` is `true`) means the user explicitly accepted a selection of nothing. The two MUST NOT be conflated.
**Rationale**: upstream's `handle.map(...)` of an empty handle array resolves `[]` rather than `undefined` (`extHostQuickOpen.ts`); a conformer that answered `[]` for a dismissal would tell the extension the user accepted an empty selection, a different, observable answer to code doing `if (result === undefined)`.
**Approved**: pending

**Decision**: single-select and multi-select both answer through the same `[Int]?` return type — a one-element array for single-select — rather than two overloads (a bare `Int?` for single-select, `[Int]?` for multi-select).
**Rationale**: `canPickMany` is a field of the request every conformer already reads; two overloads would make each conformer spell the dismissal rule (`nil` vs `[]`) twice instead of once, per the source's own doc comment.
**Approved**: pending

**Decision**: `ExtensionQuickPickItem` carries no `iconPath`, `resourceUri`, or `buttons` field, even though `QuickPickItem` declares all three.
**Rationale**: per the struct's own doc comment, `buttons` is dropped because the VS Code declaration states buttons are "not rendered when using the `showQuickPick` API" at all; `iconPath` and `resourceUri` are dropped because nothing in this repo resolves an extension-supplied icon path to an image, and a field that is always dropped reads to the next person as a capability that exists when it does not — worse than the field's absence.
**Approved**: pending

**Decision**: constructing an `ExtensionQuickPickItem` for a separator row (`isSeparator == true`) MUST set `description`, `detail`, `isPicked`, and `alwaysShow` to their defaults regardless of what the extension supplied for them.
**Rationale**: quoting the source's own doc comment on `isSeparator`, "The only property that applies is `QuickPickItem.label`. All other properties on `QuickPickItem` will be ignored and have no effect," per `vscode.d.ts`.
**Approved**: pending

**Decision**: `isPicked` and `alwaysShow` are carried truthfully regardless of `canPickMany` or the current filter text; applying VS Code's own conditions for honoring them ("only honored when the picker allows multiple selections" for `picked`; keeping a row visible despite the filter for `alwaysShow`) is deferred to the presenting conformer or, for `alwaysShow`, to `ExtensionQuickPickModel.matches(_:filter:)`.
**Rationale**: per the source's own doc comment, a type that zeroed `isPicked` out itself would leave the presenter unable to tell "the extension did not ask for this row" from "the extension asked and something upstream discarded it"; the rule for when a flag is *honored* is a presentation concern, not a parsing concern.
**Approved**: pending

