
**Decision**: `HTDVController` discards a stale response by comparing a
captured `generation` snapshot against the current `generation` after an
`await` resolves, rather than cancelling the underlying `Task`.
**Rationale**: The in-flight `dataSource.rootLevel()`/`child(for:)` call is
allowed to keep running to completion even after `popToLevel`, `clearDetail`,
or a newer `select`/`reload` has moved on; only the *result* is thrown away
(`stale-response-dropped`). This is simpler and safer than plumbing
`Task` cancellation through an arbitrary `HTDVDataSource` implementation
(which the doc comment says is "typically actors or `@unchecked Sendable`
classes wrapping a client" the engine does not control), at the cost of
occasionally letting a now-useless network/database call run to completion
in the background.
**Approved**: pending

**Decision**: `FormState`'s doc comment scopes it to "the save lifecycle";
it exposes no method invoking `spec.actions.delete` or `spec.actions.extra`,
and tracks no `isDeleting`/`deleteError` for them.
**Rationale**: Delete and "extra" actions are typically presented behind a
confirmation dialog (`FormDeleteAction.confirmationText`) that is
inherently a presentation-layer concern; keeping only the save lifecycle in
the engine layer means the presentation layer (`FormViewController`,
outside these given sources) owns exactly one additional, simple
responsibility - call the closure and handle its `throws` itself - instead
of duplicating `FormState`'s dirty-tracking machinery for actions that have
no "dirty" concept of their own.
**Approved**: pending

**Decision**: Both `HTDVController.fail(...)` and `FormState.save()` reduce
a thrown error to a single string via `(error as? LocalizedError)?.errorDescription
?? String(describing: error)`, discarding the original error's type and any
structured payload.
**Rationale**: `HTDVLoadError` and `FormState.saveError` are both declared
as plain strings meant to be shown directly to the user, so a uniform
reduction avoids either type having to know about every error type a given
`HTDVDataSource`/`FormAction` implementation might throw; the tradeoff is
that a non-`LocalizedError` type without a friendly `CustomStringConvertible`
description surfaces its raw Swift debug description to the user.
**Approved**: pending

**Decision**: `HTDVLayoutEngine.layout(...)` clamps its effective rail-width
divisor to a minimum of `1` even though `init(railWidth:minDetailWidth:)`
already `precondition`s `railWidth > 0`.
**Rationale**: `railWidth` is a mutable public `var`, so the init-time
precondition cannot stop a later assignment of `0` or a negative value (for
example, a caller collapsing a sidebar to width `0` for one layout pass);
clamping inside `layout` itself is what actually prevents a division-by-zero
or a trapping `Int` conversion at the point the value is used, rather than
only at construction.
**Approved**: pending

**Decision**: (AppKit/UIKit) `MarkdownEditing.swift` defines the
`MarkdownEditing` protocol and ships a concrete default implementation
(`PlainTextMarkdownEditing`, with AppKit and UIKit view controllers) in
the same file, unlike the other eight given sources, which hold no
AppKit/UIKit-specific code.
**Rationale**: Per the source's own comment, `PlainTextMarkdownEditing` is
explicitly a placeholder - "adequate for configuration notes until the
markdown module lands" - with the hub app expected to inject a real
implementation through `HubModules.markdownEditing`; bundling a working
default alongside the protocol lets every consumer of the Forms subsystem's
`.markdown` field render *something* today without depending on that
richer, not-yet-given module.
**Approved**: pending

