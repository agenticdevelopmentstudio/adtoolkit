
### Module-wide

- **wire-types-own-transcription**: every type this component imports and
  re-exports for the wire (the realm configuration record and its update
  input/result, the effective catalog and its badge/level entries, a realm
  badge record and its input, a level-ladder replacement input/result and
  level rung, a replay result, a realm event-type record and its input, a
  seasons window value, the gaming mode) MUST be this component's own
  transcription, never a dependency on a generated, product-specific
  vocabulary — a generic data client does not take a dependency on that
  vocabulary.
- **path-segment-encoding**: every dynamic path segment (an ecosystem id,
  or a badge/event-type id) MUST be URL-encoded before being interpolated
  into a request path.
- **api-proxy-path-prefix**: every request path this component builds
  MUST begin with the fixed `/api/gamification/` prefix, matching the
  host's generic API proxy that forwards to the backend's
  `/gamification/...` routes.
- **stateless-module**: this component MUST hold no instance- or
  module-level mutable state between calls; every operation's request
  MUST be built solely from the arguments passed to that call.
- **no-response-caching**: no operation MUST cache a prior response;
  every call MUST issue a fresh request.
- **error-propagation-unmodified**: no operation MUST catch, transform,
  or discard a failure from the underlying request; every operation's
  result MUST fail with whatever error the underlying request raised,
  unmodified — no operation itself attempts to handle that failure.

### Realm Config

- **realm-config-read**: reading a realm's configuration MUST issue a
  read to the realm-config route and resolve with the realm configuration
  record; this read is admin/owner-gated.
- **realm-config-partial-update-optionality**: updating a realm's
  configuration MUST issue a write to the realm-config route with the
  given update input as the body; every field of that input (`mode`,
  `skin`, `surfaces`, `seasons`, `timezone`) MUST be optional, so a caller
  may send any subset without the others.
- **realm-config-update-always-returns-config**: a configuration update's
  result MUST always carry the resulting realm configuration record,
  regardless of whether a replay occurred.
- **realm-config-mode-ordered-axis**: the gaming mode MUST be treated as
  one ordered axis, not a set of mutually exclusive alternatives —
  `'game'` INCLUDES everything `'gamification'` gives; it is a superset,
  not an alternative. A check for whether gaming is on at all MUST test
  the mode is not `'none'`; a check for a game-specific surface MUST test
  the mode equals `'game'`.
- **realm-config-surfaces-default-on**: each per-surface toggle MUST be
  treated as enabled unless that key is explicitly set to `false` — a
  surface is on unless set false.
- **realm-config-seasons-nullable-window**: a seasons value, whether read
  or written, MUST accept `null` to mean seasons are off, and MUST accept
  an object of `{ anchor: string, lengthDays: number }` to mean an active
  season window.
- **realm-config-replay-on-enable**: a configuration update's result MUST
  carry a `replayed` field only when the applied update raised the mode
  from `'none'` to either `'gamification'` or `'game'`, triggering a
  retroactive replay; that field MUST be absent for every other update.

### Catalog

- **catalog-effective-merge**: reading the effective catalog MUST issue a
  read to the catalog route and resolve with badge and level lists that
  are the platform's defaults merged with the realm's own overrides — the
  EFFECTIVE catalog, not the realm's overrides alone.
- **catalog-default-rows-read-only**: every catalog badge/level entry
  MUST carry a `source` of `"default"` or `"realm"`; a `source: "default"`
  row MUST be treated as read-only — only a `source: "realm"` row is
  editable or deletable.

### Badges

- **badge-create**: creating a realm badge MUST issue a create request to
  the badges route with the given input as the body and resolve with the
  created badge record; an invalid body answers a validation failure.
- **badge-input-required-field-set**: a badge create/update input MUST
  require `name`, `description`, `icon`, `statKey`, `comparator`,
  `threshold`, `badgeLine`, `tier`, `pointValue`, and `hidden` as
  non-optional values on every create or update — every field required
  by the schema — even though the corresponding fields on the read
  record (`statKey`, `comparator`, `threshold`, `badgeLine`, `tier`) are
  optional and nullable on read.
- **badge-input-omits-read-only-fields**: a badge create/update input
  MUST NOT declare an `active`, `subjectType`, or `ecosystemId` property
  — all three are declared only on the read record — so creating or
  updating a badge gives a caller no way to set a badge's active flag,
  subject type, or ownership directly.
- **badge-tier-line-override-key**: a realm badge overrides the same
  `(badgeLine, tier)` default — the pair of `badgeLine` and `tier` is the
  override key against the platform's default catalog, not an id or a
  name.
- **badge-update-excludes-defaults**: updating a realm badge MUST issue a
  write to the item's badge route with the given input as the body and
  resolve with the updated badge record; this call answers not-found for
  a platform-default badge (one whose `ecosystemId` is `null`).
- **badge-delete-clears-holdings-first**: deleting a realm badge MUST
  issue a delete request to the item's badge route and resolve with a
  `{ deleted: <id> }` result; deleting a realm-owned badge clears its
  holdings first, and MUST NOT succeed against a platform default
  (not-found).

### Levels

- **levels-replace-wholesale**: replacing a realm's level ladder MUST
  issue a write to the levels route with a body of exactly `{ rungs }`
  and resolve with a level-replacement result; this call replaces the
  entire ladder, never a partial merge.
- **levels-ladder-shape-enforced-serverside**: the sent rungs must start
  at 0 and be strictly increasing, else the request fails; the client
  performs no runtime check of that shape itself — enforcement is
  documented as the backend's, surfaced to the caller per
  **error-propagation-unmodified**.
- **levels-update-replay-hint**: a level-replacement result MUST carry
  the replaced level list plus a hint string that the owner may trigger a
  replay to backfill retroactively.

### Replay

- **replay-scoping-via-body**: triggering a replay MUST issue a create
  request to the fixed replay route (which takes no ecosystem-id segment)
  with a body of exactly `{ ecosystemId: <id> }`, and resolve with a
  replay result — the only one of this component's operations that
  carries its ecosystem scope in the body rather than the route.
- **replay-result-single-subject-fields**: a replay result's subject
  count MUST be `1` for a single-subject replay; its badge count MUST
  count newly-granted badges across the replayed subject(s); its
  points-gained field MUST be present only for a single-subject replay.

### Event Types

- **event-types-list-name-ordered**: listing a realm's event types MUST
  issue a read to the event-types route and resolve with a name-ordered
  list; this operation performs no sort of its own — ordering is
  produced server-side.
- **event-type-create**: creating an event type MUST issue a create
  request to the event-types route with the given input as the body and
  resolve with the created record; a bad input answers a validation
  failure and a duplicate name answers a conflict.
- **event-type-update**: updating an event type MUST issue a write to
  the item's event-type route with the given input as the body and
  resolve with the updated record; a foreign realm's row answers
  not-found and a colliding rename answers a conflict.
- **event-type-delete**: deleting an event type MUST issue a delete
  request to the item's event-type route and resolve with a
  `{ deleted: <id> }` result; a foreign realm's row or an unknown id
  answers not-found.
- **event-type-input-length-precondition**: an event-type input's `name`
  and `statKey` MUST both be required and bounded to at most 64
  characters — a documented caller precondition that creating/updating
  an event type does not check itself, since a bad input's rejection is
  the backend's to raise.

