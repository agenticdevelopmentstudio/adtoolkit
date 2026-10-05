
**Decision**: `ContributionPoint` is constrained to `AnyObject` and isolated to `@MainActor`.
**Rationale**: `ExtensionRegistry` holds registered points by reference identity — the same instance that applies an extension's contributions must be the one asked to withdraw them — which only a class can guarantee under Swift's value semantics; `@MainActor` follows because every implementer written so far touches main-actor state (the theme store, settings panels, the tabs registry).
**Approved**: pending

**Decision**: `ContributionRegistrations.record(_:notes:for:)` replaces an existing entry in place and moves the identifier to the end of the reported order, rather than merging the new payload into the identifier's original position.
**Rationale**: per the file's own doc comment, a re-application is the most recent application, and keeping the identifier's original position would report an order no real sequence of events produced; this also makes reload-withdraws-before-reapplying safe, since a rescan's withdraw-then-reapply of an unchanged extension still leaves exactly one entry, now at the end.
**Approved**: pending

**Decision**: both `registrations` and `notes` inside `ContributionRegistrations` are arrays, not dictionaries, even though lookup by identifier is a common operation.
**Rationale**: per the file's own doc comment, application order is the only order either collection has, and it is an order callers report back — `identifiers` is specified in it, and so is the notes list a person reads in the Extensions UI; a dictionary has no order to give back, so it cannot satisfy identifiers-in-application-order or notes-in-application-order-unfiltered.
**Approved**: pending

**Decision**: the persisted-state-absence-distinction rule is written into `ContributionPoint`'s own doc comment as a property of the contract, rather than left to each conformer to rediscover.
**Rationale**: the doc comment cites four separate prior defects (Rulings GO, GS, GV, and I1/I2), all in `ThemeContributionPoint`, that trace back to the same conflation — reading "I could not determine what this extension declares" as "this extension declares nothing" — each time deleting or orphaning a user's persisted theme. The rule is scoped to conformers whose applied state is itself persisted and user-owned; a conformer whose state is rebuilt from the manifests at every launch is explicitly exempt, because a wrong answer there costs a session, not data.
**Approved**: pending

