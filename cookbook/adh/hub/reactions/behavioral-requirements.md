
### Module-wide

- **wire-types-own-transcription**: `ReactionRow` and `ReactionCreateBody` MUST come from this module's own `./wire`, hand-narrowed from the backend's OpenAPI `Reaction` schema rather than imported from `@agentic-toolkit/adh-api-types`, per `wire.ts`'s own comment ("a generic data client must not take on" adh's product vocabulary).
- **api-proxy-path-prefix**: every request `reactionsApi` issues MUST address the fixed `BASE` path `/api/content/reactions`, or an id-suffixed path under it.
- **path-segment-encoding**: every dynamic value interpolated into a request path (`targetKind`, the joined `targetIds` batch, `reactionId`) MUST be passed through `enc` (`encodeURIComponent`) first.
- **stateless-module**: `reactionsApi` MUST hold no instance- or module-level mutable state between calls; every method's request MUST be built solely from the arguments passed to that call. `MAX_TARGET_IDS` is a fixed constant, not per-call state.
- **no-response-caching**: none of `list`, `add`, or `remove` MUST cache a prior response; every call MUST issue a fresh `authedJson`/`authedRequest` request.
- **error-propagation-unmodified**: none of `list`, `add`, or `remove` MUST catch, transform, or discard a rejection from `authedJson`/`authedRequest`; each method's returned promise MUST reject with whatever error that call throws, unmodified — no method body contains a `try`/`catch`.

### Reading

- **list-target-id-cap**: `list(targetKind, targetIds)` MUST split its de-duplicated, non-empty `targetIds` into batches of at most `MAX_TARGET_IDS` (200) before requesting, per its own comment describing this as "the backend's cap on one batched read."
- **list-empty-input-short-circuits**: `list` MUST resolve to `[]` without issuing any request when, after filtering falsy entries and de-duplicating, zero target ids remain — per its own comment, "the backend requires at least one, and a pane whose list has not arrived yet should not send a call it knows is a 400."
- **list-deduplicates-target-ids**: `list` MUST de-duplicate `targetIds` (via `new Set`) and MUST drop any falsy entry (via `.filter(Boolean)`) before batching.
- **list-chunks-issued-concurrently**: when `targetIds` spans more than one batch, `list` MUST issue all batches' requests concurrently (`Promise.all`), not sequentially.
- **list-merges-chunks-in-order**: `list` MUST return the merged rows in batch order (`pages.flatMap`), regardless of which batch's request settles first over the network.
- **list-scope-is-ecosystem-public**: `list` MUST NOT filter its result to the calling actor's own reactions; per the module's own top-of-file comment, "the list is PUBLIC within the ecosystem (everyone sees who reacted); only writes are scoped to the actor."
- **to-reaction-field-projection**: `toReaction` MUST map a `ReactionRow` to a `Reaction` carrying exactly `id`, `customerId`, `targetKind`, `targetId`, `emoji`, and `createdAt`; it MUST NOT carry the row's `ecosystemId` or `deletedAt` fields into the mapped `Reaction`.

### Writing

- **add-idempotent-on-repeat**: `add(targetKind, targetId, emoji)` MUST always resolve with a `Reaction` for a POST to `BASE` with `{ targetKind, targetId, emoji }`; per the module's own top-of-file comment, "ADDING is idempotent on (actor, target, emoji) — a repeat POST returns the existing row rather than a 409, so a double-click is not an error to handle."
- **remove-addressed-by-reaction-id**: `remove(reactionId)` MUST issue a DELETE to `` `${BASE}/${enc(reactionId)}` ``, addressing the caller's own reaction by ITS id, never by emoji or by subject — per the module's own comment, this is "which is why `tally` hands back the caller's own reaction id rather than a bare boolean."

### Folding

- **tally-counts-per-emoji**: `tally(reactions, viewerId)` MUST return exactly one `ReactionTally` per distinct emoji present in `reactions`, whose `count` equals the number of `reactions` entries carrying that emoji.
- **tally-mine-identifies-viewers-own-reaction**: for each `ReactionTally`, `mine` MUST be the `id` of the one entry in `reactions` whose `emoji` matches and whose `customerId` equals `viewerId`, or `null` when no such entry exists.
- **tally-sort-order**: `tally`'s returned array MUST be sorted by `count` descending; two emoji with equal counts MUST keep the order in which the emoji first appeared in `reactions`, per the function's own comment ("ties keep the order the emoji first appeared, so a bar does not reshuffle as counts even up").
- **tally-null-viewer-honest-rendering**: `tally` MUST accept `viewerId: string | null`; when `viewerId` is falsy (`null` or `""`), every returned `ReactionTally.mine` MUST be `null` rather than a guess, per the function's own comment ("pass null when unknown and every tally reads as not-mine — the honest rendering rather than a wrong one").
- **by-target-groups-preserving-order**: `byTarget(reactions)` MUST return a `Map<string, Reaction[]>` keyed by `targetId`, where each bucket's entries appear in the same relative order they held in the input `reactions` array.
- **by-target-omits-empty-targets**: `byTarget` MUST NOT create an entry for a `targetId` that no reaction in the input names; such a target MUST simply be absent from the returned `Map` rather than mapped to an empty array.

