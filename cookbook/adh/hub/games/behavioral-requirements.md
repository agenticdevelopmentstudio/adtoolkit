
### Closed-set types

- **game-character-names-values**: `GameCharacterNames` MUST be one of
  `"off"`, `"optional"`, `"required"` — `game.games.character_names`, a
  closed set enforced by a database `check`, with `"off"` as the default
  (`games.ts`).
- **game-status-values**: `GameStatus` MUST be one of `"active"`,
  `"hidden"`, `"retired"` — `game.games.status`, defaulting to `"active"`;
  `"hidden"` is delisted but still startable by anyone holding a link or a
  save, and `"retired"` is neither (`games.ts`).
- **game-event-log-values**: `GameEventLog` MUST be one of `"debug"`,
  `"authoritative"` — `game.games.event_log`, a closed set enforced by a
  database `check`, defaulting to `"debug"`; `"authoritative"` means the
  event log is the truth and is never swept regardless of the retention
  window (`games.ts`).
- **game-definition-status-values**: `GameDefinitionStatus` MUST be one of
  `"active"`, `"retired"` — narrower than `GameStatus`'s three values,
  because a definition is either offered or it is not; nothing about it is
  "startable" (`games.ts`).
- **game-effect-trigger-values**: `GameEffectTrigger` MUST be one of
  `"on_use"`, `"on_equip"`, `"on_hold"`, `"on_enter"`, `"on_acquire"` —
  `game.effects.trigger`, a closed set enforced by a database `check`
  (`games.ts`).
- **game-effect-operation-values**: `GameEffectOperation` MUST be one of
  `"add"`, `"multiply"`, `"set"` — `game.effects.operation`, also a closed
  set enforced by a database `check` (`games.ts`).

### Row shapes and invariants

- **game-shape**: `Game` MUST carry `id`, `slug`, `name`, `description`
  (`string`), `engine`, `engineConfig` (`string`), `characterNames`,
  `status`, `eventLog`, `eventRetentionDays` (`number`), `createdAt`,
  `updatedAt` (`games.ts`).
- **game-id-is-opaque**: `Game.id` MUST be treated as an opaque,
  server-generated UUID with no address of its own — `game.games` is NOT
  rdid-addressed, and a game is reached as "the game of ecosystem X"
  through its product's ecosystem rdid rather than by an id-based address
  (`games.ts` header comment).
- **game-event-retention-semantics**: `Game.eventRetentionDays` MUST be
  read as the day window the `"debug"` sweep applies, and MUST be treated
  as meaningless when `eventLog` is `"authoritative"`, per the field's own
  doc comment (`games.ts`).
- **game-input-shape**: `GameInput` MUST carry exactly `slug`, `name`,
  `description`, `engine`, `engineConfig`, `characterNames`, `status`,
  `eventLog`, `eventRetentionDays` — no `id`, `createdAt`, or `updatedAt`
  (`games.ts`).
- **game-definition-shape**: `GameDefinition` MUST carry `id`, `gameId`,
  `authorCustomerId`, `kind`, `key`, `name`, `description` (`string`),
  `status`, `sortOrder`, `data` (`string`), `createdAt`, `updatedAt`
  (`games.ts`).
- **game-definition-key-scope**: `GameDefinition.key` MUST be read as the
  stable handle an engine refers to, unique WITHIN `kind` rather than
  across the whole game (`games.ts`).
- **game-definition-input-excludes-author**: `GameDefinitionInput` MUST
  carry `kind`, `key`, `name`, `description`, `status`, `sortOrder`, `data`
  and MUST NOT carry `authorCustomerId` — that column is ROUTE-MANAGED,
  stamped from the caller by the backend's `POST /game/terms`, and masked
  out of the generic CRUD body, so a client that sent it would have the
  value silently stripped rather than refused (`games.ts` header comment).
- **game-effect-shape**: `GameEffect` MUST carry `id`, `gameId`,
  `definitionId`, `key`, `trigger`, `target`, `operation`, `value`
  (`number`), `duration` (`number | null`), `sortOrder`, `createdAt`,
  `updatedAt` (`games.ts`).
- **game-effect-duration-semantics**: `GameEffect.duration` of `null` MUST
  be read as "for as long as it is held," never as "no duration," and MUST
  NOT be confused with `0`, which means the effect expires immediately
  (`games.ts`).
- **game-effect-sort-order-is-load-bearing**: `GameEffect.sortOrder` MUST
  be treated as load-bearing for correctness — applying an `"add"` effect
  before a `"multiply"` effect produces a different result than the
  reverse order (`games.ts`).
- **game-effect-input-allows-blank-selection**: `GameEffectInput.trigger`
  and `GameEffectInput.operation` MUST accept `""` in addition to their
  respective closed sets, representing a draft that has not yet chosen a
  value; neither closed set has a default, so a blank draft carries no
  trigger or operation until one is picked (`games.ts`).
- **game-mapping-shape**: `GameMapping` MUST carry `id`, `gameId`, `kind`
  (an unconstrained, game-defined string with no database `check`),
  `fromId`, `toId`, `amount` (`number`), `sortOrder`, `createdAt`,
  `updatedAt` (`games.ts`).
- **game-mapping-input-shape**: `GameMappingInput` MUST carry `kind`,
  `fromId`, `toId`, `amount`, `sortOrder` (`games.ts`).

### The two column crossings (wire mapping)

- **nullable-text-read**: `gameFromWire` and `definitionFromWire` MUST map
  a `description` of `null` on the wire to `""` on the client type
  (`games.ts`; pinned by "reads a null description as an empty field" and
  "applies the same reading rule to a definition" in `games.test.ts`).
- **nullable-text-write**: `gameToWire` and `definitionToWire` MUST map a
  `description` that is empty or all-whitespace, after trimming, to `null`
  on the wire — an empty box means the COLUMN is empty, never an empty
  string stored in it — via the shared `emptyToNull` helper (`games.ts`;
  pinned by "writes an empty box as an empty COLUMN, not an empty string
  in one" in `games.test.ts`).
- **jsonb-read-as-indented-text**: `gameFromWire`/`definitionFromWire`
  MUST render a parsed `engineConfig`/`data` JSON value as the two-space
  indented text produced by `JSON.stringify(value, null, 2)`, via the
  shared `jsonToText` helper (`games.ts`; pinned by "reads a config OBJECT
  as the JSON text the operator edits" in `games.test.ts`).
- **jsonb-write-as-parsed-value**: `gameToWire`/`definitionToWire` MUST
  parse the operator's JSON text back into a JSON value before sending it,
  via the shared `textToJson` helper, never sending the raw text string
  (`games.ts`; pinned by "parses the operator's text into a JSON VALUE on
  the way out" in `games.test.ts`).
- **jsonb-empty-value-differs-by-column**: `jsonToText`/`textToJson` MUST
  use `{}` (the empty JSON object) as `engineConfig`'s empty value, because
  `games.engine_config` is `NOT NULL` with a `{}` default, and MUST use
  `null` as `data`'s empty value, because `definitions.data` is nullable
  (`games.ts`; pinned by "crosses an empty engine config as the empty
  OBJECT, both ways" and "crosses an empty definition payload as NULL,
  both ways" in `games.test.ts`).
- **jsonb-read-null-as-empty-text**: `jsonToText` MUST return `""` when the
  wire value is `null` or `undefined`, whatever the client's own type
  claims about that column's nullability (`games.ts`; pinned by "reads a
  null engine config as an empty field, whatever the type says" in
  `games.test.ts`).
- **jsonb-write-refuses-unparseable-text**: `textToJson` MUST throw a
  `clientRefusal` (an `Error` with a `status` of `400`) carrying the
  message `"<label> must be valid JSON."` when the trimmed text fails
  `JSON.parse`, where `<label>` is `"Engine config"` for `gameToWire` and
  `"Data"` for `definitionToWire` (`games.ts`; pinned by "refuses
  unparseable JSON with a 4xx the shared reporter drops" in
  `games.test.ts`).
- **jsonb-serialization-collapse-is-defensive**: `jsonToText` MUST return
  `""` (never `"undefined"`) if `JSON.stringify` itself answers
  `undefined`, a branch the source's own comment states nothing a `jsonb`
  column can hold reaches, kept only because the function is a cast over
  whatever the route returns (`games.ts`).

### `gamesApi`

- **games-list-scoped-by-ecosystem-query**: `gamesApi.list(ecosystemId?)`
  MUST request `GET /api/game/games?ecosystemId=<encoded ecosystemId>`
  when given an id, and MUST request the bare `/api/game/games` URL when
  omitted (`games.ts`; pinned by "filters the catalog by ecosystem in the
  QUERY" and "asks for the whole catalog when no ecosystem is named" in
  `games.test.ts`).
- **games-list-sorted-by-name**: `gamesApi.list` MUST sort the mapped rows
  by `name` via the locale-aware `sortByText` helper, because the generic
  list route applies no `ORDER BY` of its own and returns rows in whatever
  order the query planner produces (`games.ts`).
- **games-for-ecosystem-single-result**: `gamesApi.forEcosystem(ecosystemId)`
  MUST call `gamesApi.list(ecosystemId)` and return its first row, or
  `null` when the list is empty; this is safe because a partial unique
  index (`uq_games_ecosystem` on `(ecosystem_id) WHERE deleted_at IS NULL`)
  guarantees at most one live game per ecosystem (`games.ts`; pinned by
  "resolves the one game of an ecosystem" and "answers null for an
  ecosystem with no game" in `games.test.ts`).
- **games-create-ecosystem-in-body**: `gamesApi.create(input, ecosystemId)`
  MUST send `ecosystemId` as a field of the POST BODY (alongside
  `gameToWire(input)`), never as a query parameter, because the generic
  POST route reads no query params at all (`games.ts`; pinned by "stamps a
  created game into its ecosystem through the BODY, not the query" in
  `games.test.ts`).
- **games-create-conflict-mapping**: `gamesApi.create` MUST catch any error
  from the POST and pass it to `rethrowConflict` with the friendly message
  `A game with slug "<input.slug>" already exists.`, which rethrows that
  friendly message only when the caught error's own message matches
  `/already exists/i`, and otherwise rethrows the caught error unchanged
  (`games.ts`, `http.ts`; pinned by "names the entity, not the constraint,
  when a slug is taken" in `games.test.ts`).
- **games-update-omits-ecosystem**: `gamesApi.update(id, input)` MUST PUT
  to `/api/game/games/<encoded id>` with a body built from `gameToWire(input)`
  alone, and MUST NOT resend an ecosystem id in any form — a game does not
  move between ecosystems, and this PUT is the only route that could try
  (`games.ts`; pinned by "does not resend the ecosystem on update" in
  `games.test.ts`).
- **games-update-conflict-mapping**: `gamesApi.update` MUST map a caught
  error through `rethrowConflict` with the same friendly-message rule as
  `games-create-conflict-mapping`, using `input.slug` in the message
  (`games.ts`).
- **games-delete-no-body**: `gamesApi.delete(id)` MUST send `DELETE
  /api/game/games/<encoded id>` with no request body and resolve to `void`
  (`games.ts`).
- **id-percent-encoded-in-path**: every path segment built from a caller
  id (`gamesApi.update`/`delete`, and every `childApi` `update`/`delete`)
  MUST be percent-encoded via the shared `enc` helper (`encodeURIComponent`)
  before being interpolated into the URL (`games.ts`, `client-helpers.ts`;
  pinned by "percent-encodes the id in the path" in `games.test.ts`).

### Child collection factory (`gameDefinitionsApi` / `gameEffectsApi` / `gameMappingsApi`)

- **child-api-shared-factory**: `gameDefinitionsApi`, `gameEffectsApi`, and
  `gameMappingsApi` MUST each be produced by the one `childApi` factory
  function, parameterized by a base route and a `{fromWire, toWire}` codec,
  rather than three independent implementations (`games.ts`).
- **child-list-scoped-by-game-query**: `childApi(...).list(gameId)` MUST
  request `GET <base>?gameId=<encoded gameId>` and map every row through
  the codec's `fromWire` (`games.ts`; pinned by "filters each child
  collection by game in the QUERY" in `games.test.ts`).
- **child-list-unsorted**: `childApi(...).list` MUST NOT apply any sort of
  its own to the rows it returns — unlike `gamesApi.list`, it returns the
  mapped rows in the order the generic list route's query planner produced
  them (`games.ts`).
- **child-create-parent-in-body**: `childApi(...).create(gameId, input)`
  MUST send `gameId` as a field of the POST BODY (alongside
  `codec.toWire(input)`), never as a query parameter, for the same reason
  as `games-create-ecosystem-in-body` (`games.ts`; pinned by "parents a
  created definition/effect/mapping through the BODY, not the query" in
  `games.test.ts`).
- **child-update-full-put**: `childApi(...).update(id, input)` MUST PUT to
  `<base>/<encoded id>` with a body built from `codec.toWire(input)` alone
  (`games.ts`).
- **child-delete-no-body**: `childApi(...).delete(id)` MUST send `DELETE
  <base>/<encoded id>` with no request body and resolve to `void`
  (`games.ts`).
- **child-create-update-no-conflict-mapping**: `childApi(...).create` and
  `childApi(...).update` MUST propagate any error from the request
  unchanged — neither wraps its call in a `try`/`catch`, unlike
  `gamesApi.create`/`update`, so a 409 conflict on a definition, effect, or
  mapping surfaces as whatever raw message the generic CRUD route returned,
  never a `gamesApi`-style friendly, entity-named message (`games.ts`).
- **definitions-use-real-codec**: `gameDefinitionsApi` MUST be built with
  `{ fromWire: definitionFromWire, toWire: definitionToWire }`, applying
  the nullable-text and jsonb crossings on every read and write
  (`games.ts`).
- **effects-mappings-use-identity-codec**: `gameEffectsApi` and
  `gameMappingsApi` MUST be built with the shared `identityCodec`, whose
  `fromWire` returns the row unchanged and whose `toWire` spreads the
  input into a plain object — because neither `GameEffect` nor
  `GameMapping` has a nullable-text or jsonb column requiring translation
  (`GameEffect.duration` is already typed `number | null` with no crossing
  needed) (`games.ts`).

### Routing

- **fixed-route-bases**: the module MUST address exactly four fixed base
  routes — `/api/game/games`, `/api/game/definitions`, `/api/game/effects`,
  `/api/game/mappings` — as module-level constants, never built or
  discovered at runtime (`games.ts`).
- **api-prefix-is-a-rewrite**: the `/api` prefix on every route MUST be
  understood as a frontend rewrite (mapping `/api/:path*` onto the
  backend's own prefix-less routes) rather than a literal backend path
  segment, the same shape `/api/team/teams` and `/api/bucket/buckets` use
  elsewhere in the app (`games.ts` header comment).

