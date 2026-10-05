
**Decision**: `ExtensionInputBoxRequest.valueSelection` is declared as an optional `Range<Int>` rather than upstream's raw two-number tuple.
**Rationale**: per the source's own doc comment, a `Range` "rejects a pair this type could not otherwise represent — reversed, negative, or past value's end — rather than trapping when a presenter eventually tried to build a Range from a raw tuple"; pushing the rejection to construction time, in `parseValueSelection(from:valueLength:)` outside this file, means every consumer of `ExtensionInputBoxRequest` already holds a valid `Range` and never has to re-validate it.
**Approved**: pending

**Decision**: `ExtensionInputValidationSeverity` has no case corresponding to upstream's internal `Severity.Ignore`.
**Rationale**: per the source's own doc comment, a severity is only ever attached to a message that exists in this type's model, so "nothing to show" is represented by the complete absence of an `ExtensionInputValidation` value rather than by a fourth severity case that would also require an empty message.
**Approved**: pending

**Decision**: The severity cases are spelled `.information`, `.warning`, `.error`, matching this directory's own `ExtensionMessageSeverity` spelling rather than transcribing upstream's `Info`/`Warning`/`Error` member names verbatim.
**Rationale**: stated directly in the source's own doc comment — a Swift enum case name is this codebase's word, not a transcription of upstream's.
**Approved**: pending

**Decision**: `ExtensionInputBoxPresenting` is declared as its own protocol rather than as an additional method on `ExtensionMessagePresenting` or `ExtensionQuickPickPresenting`.
**Rationale**: the source's own doc comment points to `ExtensionQuickPickPresenting`'s doc for the interface-segregation reasoning that already governs this adaptor's other seam — a conformer right for one presentation is often the wrong one for another, and one protocol carrying every seam's members would force every conformer to implement presentations it has no business showing; the cost, paid at `MainThreadWindow.init`, is one presenter parameter per seam rather than one shared parameter.
**Approved**: pending

**Decision**: `ExtensionInputBoxPresenting` states that a conformer must not accept a value whose most recent call to `validate` answered `.error` severity, but enforces nothing itself.
**Rationale**: per the source's own doc comment, enforcing that rule belongs to whatever type builds a text field around this — task 5.5b-iv, not this type or `MainThreadWindow`, which only carries the presenter's answer back to the extension; the protocol states the contract once so every conformer is held to the same rule, while leaving the UI-level mechanics to each conformer.
**Approved**: pending

