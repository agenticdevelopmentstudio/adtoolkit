
**Decision**: The parent id (`ecosystemId` for a game, `gameId` for a
child row) travels as a query parameter on LIST but as a BODY field on
CREATE, rather than using one spelling for both.
**Rationale**: The generic CRUD backend's LIST route reads query
parameters as column filters, while its POST route reads no query
parameters at all — a create that named its parent in the query string
would either insert a row with no parent (a `NOT NULL` violation surfacing
as an opaque backend fault) or, for the ecosystem case specifically,
silently default to the caller's own ecosystem instead of the one they
asked for. Using one consistent spelling would be simpler to read but
would misfile data.
**Approved**: pending

**Decision**: `gamesApi.forEcosystem` is implemented as `list(ecosystemId)[0]
?? null` rather than as a dedicated single-row backend endpoint.
**Rationale**: `game.games` is guarded by a partial unique index,
`uq_games_ecosystem` on `(ecosystem_id) WHERE deleted_at IS NULL`, so a
column-filtered list for one ecosystem can never return more than one live
row. Reusing the existing LIST route and taking the first result costs one
fewer backend endpoint to build and maintain, and the safety of doing so
follows directly from a database constraint rather than a client-side
assumption.
**Approved**: pending

**Decision**: `engineConfig`'s empty JSON value is `{}` while `data`'s
empty JSON value is `null`, and `jsonToText`/`textToJson` take that value
as an explicit `emptyValue` parameter rather than hardcoding one shared
empty representation.
**Rationale**: `games.engine_config` is `NOT NULL` with a `{}` default, so
its empty state IS the empty object; `definitions.data` is nullable, so
its empty state IS the null column. Posting `null` to the first would 500
at the column; posting `{}` to the second would show the operator two
characters they never typed. The two columns' empties are a schema fact,
not a preference, so the helper is parameterized rather than picking one
answer for both.
**Approved**: pending

**Decision**: `gamesApi.create`/`update` catch and remap a conflict to a
friendly, entity-named message; the three `childApi`-built clients
(`gameDefinitionsApi`, `gameEffectsApi`, `gameMappingsApi`) catch nothing
at all.
**Rationale**: This is a genuine, current asymmetry, not an oversight this
recipe is inventing a justification for: `gamesApi.create`'s own
`rethrowConflict` call names the one conflict a game's create/update path
is known to hit (a duplicate `(ecosystem, slug)`), while the shared
`childApi` factory was written generically across three row types with no
single friendly message that fits all three. A future friendly-message
addition for a child collection should follow `rethrowConflict`'s existing
message-sniffing pattern rather than inventing a new one.
**Approved**: pending

**Decision**: `rethrowConflict` (in `http.ts`) decides whether to remap an
error by testing the caught error's `.message` against `/already
exists/i`, not by checking its HTTP status code.
**Rationale**: Per `http.ts`'s own doc comment, generic CRUD answers a
duplicate row or identifier with an HTTP 409 whose message contains
"already exists" — but a 409 can also mean a different kind of conflict
with a different message. Matching on the message content, rather than on
the status code alone, keeps `rethrowConflict` from friendly-ifying a 409
that means something else; the cost is that a genuine duplicate whose
backend message happens not to contain that exact phrase would pass
through unmapped, which is the behavior `games-create-conflict-mapping`
and `games-update-conflict-mapping` document as-is rather than as an
idealized "always maps a 409."
**Approved**: pending

