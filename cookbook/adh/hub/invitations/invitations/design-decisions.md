
**Decision**: Document the Apple admin-facing topics and the web
recipient-facing client in one recipe, framed as two actors' views into one
domain rather than as two ports of one feature.
**Rationale**: `RequestsTopic`/`PendingUsersTopic`/`InvitesTopic` and
`invitationsApi` share no code, no data shapes, and no consumer — an admin
never calls `preview`/`verify`/`accept`/`registerWithInvite`, and a
recipient never sees an `InvitationRequest` or an `AdminNote`. Splitting them
into two recipes would hide that they are nonetheless the same domain from
two sides of one invite's lifecycle (a request or pending user becomes an
invite; an invite is what a recipient previews, verifies, and accepts or
registers from).
**Approved**: pending

**Decision**: Take `AdminNotesRail.rewrite`'s dependencies (`dataSource`,
`ecosystemID`, subject, subject id, transform) as explicit `Sendable`
parameters on a `nonisolated static` function rather than capturing `self`
on an instance method.
**Rationale**: The source's own doc comment on `rewrite` explains this
directly: capturing `self` (a `@MainActor` struct) inside a closure that must
itself be `@Sendable` (because `FormAction`/`FormDeleteAction.perform`
require a `@Sendable` closure) would force `AdminNotesRail` itself to be
`Sendable`, which it is not; taking every dependency as an explicit,
already-`Sendable` parameter avoids that requirement entirely.
**Approved**: pending

**Decision**: Reuse `CustomersTopic.emailPattern`/`emailMessage` in the
add-users spec rather than defining a second email pattern/message local to
`PendingUsersTopic`.
**Rationale**: Both domains validate the same shape of value (an email
address) for the same reason (a contact field with the same required-format
semantics); reusing the Customers domain's own constants keeps the two
domains' email validation identical and keeps the pattern/message defined in
exactly one place.
**Approved**: pending

**Decision**: Keep three different error-surfacing strategies across
`preview`, `verify`, `accept`, and `registerWithInvite` rather than
unifying them into one.
**Rationale**: This recipe documents each strategy as the given source
defines it (per **Error states**) rather than silently normalizing them or
treating the divergence as a defect this recipe should paper over; a
reviewer deciding whether to unify these four methods' error handling is a
product/API decision outside the scope of describing the code as it is.
**Approved**: pending

**Decision**: `preview` does not fold a network-level failure into the `invalid` result; it rejects, contradicting its own "Never throws" doc comment.

**Rationale**: it is undecided whether "Never throws" was meant to cover network failures or only HTTP-status failures; closing the gap takes either a catch that folds a network exception into the same `{ state: "invalid", ... }` result or a narrower doc comment scoping "Never throws" to HTTP-status failures.

**Approved**: pending

