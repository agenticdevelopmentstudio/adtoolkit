
**Decision**: `gamification.ts` transcribes its own wire types into
`wire.ts` rather than importing generated types from
`@agentic-toolkit/adh-api-types`.
**Rationale**: the module's own comment states this directly — "a
generic data client does not take a dependency on adh's generated
product vocabulary," following the same pattern the comment cites for
`ecosystems/wire.ts`. This keeps the `packages/data` layer
product-agnostic at the cost of a second, hand-maintained copy of the
backend's `Gamification*` schemas that must be kept in sync by hand.
**Approved**: pending

**Decision**: none of the twelve `gamificationApi` methods intercept a
documented 400/404/409 response into a friendlier, entity-named message
— every rejection propagates from `authedJson` unmodified
(`error-propagation-unmodified`).
**Rationale**: the source does not explain why. This is a notable
divergence from the sibling component
[Ecosystems](adtoolkit://cookbook/adh/hub/ecosystems/ecosystems),
whose `ecosystems.ts` and `identifiers.ts` call `rethrowConflict` to
turn a backend 409 into a friendly, entity-named message before it
reaches a caller. This recipe records the observed divergence rather
than inventing a motive the source does not state.
**Approved**: pending

