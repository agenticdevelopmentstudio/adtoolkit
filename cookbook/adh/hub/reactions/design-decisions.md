
**Decision**: `reactions.ts` transcribes its own wire types into `wire.ts` by hand from the backend's OpenAPI `Reaction` schema, rather than importing generated types from `@agentic-toolkit/adh-api-types`.
**Rationale**: `wire.ts`'s own comment states this directly — the toolkit's generic data client "must not take on" adh's product vocabulary. This keeps the `packages/data` layer product-agnostic at the cost of a second, hand-maintained copy of the backend's `Reaction` schema that must be kept in sync by hand, per the same comment ("the cost is that a backend contract change is caught by keeping this in sync, not by the build").
**Approved**: pending

**Decision**: `add` is documented as idempotent on `(actor, target, emoji)` (a repeat POST returns the existing row, not a 409), while `remove` carries no equivalent documented guarantee for a repeat call against an already-removed id.
**Rationale**: the module's own top-of-file comment calls out idempotent `add` and id-addressed `remove` as two of the "three things the surface does that a caller must not re-derive," but says nothing about repeating a `remove`. The asymmetry is recorded rather than resolved; see `repeat-remove-behavior` under Edge Cases.
**Approved**: pending

**Decision**: this component owns no reaction UI state — no toggle logic, no optimistic update, no re-fetch-after-write. `add`/`remove` resolve once and return; the caller decides when and how to re-read.
**Rationale**: `tally` and `byTarget` are pure folds over whatever `Reaction[]` a caller already has; the module comment frames the batched `list` read as the caller's job "rendering a pane," not this client's. The sibling presentational component [ReactionBar](agenticdevelopertoolkit://recipes/reaction-bar) is built on exactly this split — it is stateless itself and calls back with an emoji, leaving the write and the re-read to its consumer — the same division this data client assumes.
**Approved**: pending

