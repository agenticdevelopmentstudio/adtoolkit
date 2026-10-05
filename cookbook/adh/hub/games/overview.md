
`hub-domain-games` is the Games catalog domain logic: the web client for the
four OPERATOR-WRITABLE tables of the `game` schema (`game.games`,
`game.definitions`, `game.effects`, `game.mappings`), built over adh's
generic CRUD routes. One source of truth, `packages/web/packages/data/src/games/games.ts`,
exports `gamesApi` (the catalog record itself) and three same-shaped child
clients, `gameDefinitionsApi`, `gameEffectsApi`, and `gameMappingsApi`,
produced by one shared factory, `childApi`. The module's own header comment
states the boundary this recipe holds to deliberately: the `game` schema has
eight other tables that hold PLAYER state, none of which have an operator
read path, and this client never reaches them.

Two structural facts run through every operation this recipe documents.
First, a SCOPING asymmetry: the parent id (`ecosystemId` for a game,
`gameId` for a child row) is a query-string filter on LIST and a BODY field
on CREATE, because the generic LIST route reads query params and the
generic POST route reads none — the two spellings are not interchangeable,
and using the wrong one either misfiles a row under the caller's own
ecosystem or fails a `NOT NULL` constraint. Second, a WIRE crossing: four
columns (`games.description`, `definitions.description`, both nullable
`text`; `games.engine_config`, `definitions.data`, both `jsonb`) are `string`
on this client's types but are not strings on the wire, and `gameFromWire`/
`gameToWire`/`definitionFromWire`/`definitionToWire` hold both crossings in
one place rather than scattering the translation across call sites.

