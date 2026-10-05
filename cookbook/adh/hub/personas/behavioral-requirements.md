
### Data shapes

- **persona-data-source-protocol**: the persona data source contract MUST expose operations to
  list personas, get one by id, create, update, delete, and list available services.
- **persona-value-shape**: a persona record MUST carry every field of a persona row: `id`, `slug`,
  `name`, `description`, `visibility`, `model`, `serviceId`, `appId`, `avatarAttachmentId`,
  `modelPrompt`, `voice`, `character`, `examples`, `cannedChat` (opaque JSON), `chatStatus` (opaque
  JSON), `createdAt`, `updatedAt`, `ownedEcosystemId`, `corpusEcosystemId`.
- **persona-body-projection**: deriving a persona's create/update payload from its full record
  MUST use exactly `slug, name, description, modelPrompt, voice, character, examples,
  avatarAttachmentId, serviceId, model, visibility, cannedChat, chatStatus` — the same fields both
  implementations send — and MUST exclude the server-owned fields `id`, `createdAt`, `updatedAt`,
  `ownedEcosystemId`, `corpusEcosystemId`.
- **persona-decode-tolerates-unknown-fields**: decoding a persona record from a payload that
  carries fields the record does not declare (e.g. `userId`, `ownerKind`, `ownerId`) MUST succeed
  and MUST silently drop those fields — a deliberate, lossy projection onto the subset this domain
  needs, not a decoding failure.
- **persona-service-shape**: a persona service record MUST carry `id`, `name`, `providerKind`,
  `baseUrl`, `connectStatus`, and a list of service-model records; a service-model record MUST
  carry `id` and an optional `displayName`.
- **canned-chat-and-chat-status-are-opaque-json**: a persona's `cannedChat` and `chatStatus`
  fields MUST be treated as opaque JSON values whose equality comparison treats an integer and an
  equal-valued floating-point number as the same value, so round-tripped data is never seen as
  changed when it is not. One implementation MAY pass this tree through untouched, without
  parsing, validating, or resolving its shape (see Chat status resolution below, which does parse
  and resolve it on another implementation) — the two need not share an internal representation.

### Facet navigation

- **personas-root-level-lists-personas**: the root level MUST list every persona as one navigation
  item per persona (label = name, sublabel = slug, an icon suggesting a person) under a navigation
  level with id `"personas"`, title `"Personas"`, empty message `"No personas yet."`, and a create
  action titled `"New Persona"` that opens the persona-creation form.
- **personas-root-level-wraps-errors**: the root-level listing MUST wrap and rethrow any error
  from the underlying list operation as a wrapped domain error.
- **persona-child-resolves-by-id**: resolving a persona's child content MUST read the first path
  segment as a persona id and MUST return an empty result when no id is present.
- **persona-child-notfound-is-empty**: resolving a persona's child content MUST treat a not-found
  error from the get-by-id operation as an empty result rather than propagate it; every other
  error MUST be wrapped and rethrown.
- **persona-topics-rail-order**: with only a persona id in the path, resolving its child content
  MUST return a facet-rail level whose items are exactly the 13 declared facets, in the fixed
  order `identity, description, personality, purpose, project, knowledge, memory, abilities,
  permissions, access, demo, chatStatus, llm`, each leading to a detail form.
- **llm-facet-fetches-services**: resolving child content MUST fetch the list of available
  services only when the resolved facet id is `"llm"`; for every other facet it MUST pass an
  empty services list without fetching.
- **unsupported-facets-show-notice**: for a facet id outside the currently supported set
  (`project, knowledge, memory, abilities, permissions, access, demo, chatStatus` — 8 of the 13
  declared facets), resolving child content MUST return a detail form whose sole value, keyed
  `"notice"`, is exactly the fixed unavailable-facet message, and the facet's form specification
  MUST be absent for that facet id.
- **create-spec-defaults**: the persona-creation form MUST offer required `name` and `slug` fields
  (`slug` pattern-validated against the slug pattern), plus optional `description` and
  `modelPrompt` fields; on save it MUST build a persona payload from the entered
  `name`/`slug`/`modelPrompt`, MUST map `description` through the blank-to-nothing helper, and
  MUST hardcode `model: ""` and `visibility: "private"` regardless of any other input.
- **identity-facet-fields**: the `"identity"` facet MUST edit exactly `name` (required), `slug`
  (required, pattern-validated against the slug pattern, with the pattern's own
  validation-failure message), and `visibility` (required select over exactly `public`, `hub`,
  `private`); it MUST offer a delete action titled `"Delete persona"` whose confirmation text is
  exactly `Delete persona "<name>"? This cannot be undone.`
- **description-facet-fields**: the `"description"` facet MUST edit exactly one optional
  `description` textarea, mapped through the blank-to-nothing helper on save.
- **personality-facet-fields**: the `"personality"` facet MUST edit exactly `character`, `voice`,
  and `examples` (all optional textareas), each mapped through the blank-to-nothing helper on
  save.
- **purpose-facet-fields**: the `"purpose"` facet MUST edit exactly one optional markdown field
  keyed `modelPrompt`, and on save MUST assign the entered value directly, defaulting to `""`
  when absent (it does not route through the blank-to-nothing helper).
- **llm-facet-service-model-options**: the `"llm"` facet's `serviceId` select MUST offer `"No
  service"` plus one option per available service; its `model` select MUST offer `"Pick a service
  first"` when no service is selected or `"No model selected"` when one is, plus one option per
  that service's models (falling back to the model's own id when its display name is absent).
- **llm-facet-clears-invalid-model**: on save, the `"llm"` facet MUST clear the `model` value to
  nothing whenever the resolved `serviceId` is absent or the chosen service's models do not
  contain a model with that id — it MUST NOT persist a `model` the selected service does not
  actually offer.
- **facet-save-composes-full-body**: every facet's save action MUST start from the persona's full
  current payload, apply only that facet's edits, and send the entire composed payload as an
  update — fields the facet does not touch MUST ride along unchanged.
- **unknown-path-is-empty**: resolving child content MUST return an empty result for an empty
  path, for a path whose first item's id matches no persona, and for a path whose second item's
  id matches no declared facet.

### CRUD and rename semantics

- **personas-list-scoped-by-workspace**: the list operation MUST forward an optional `workspace`
  slug as a query parameter; when supplied, the result MUST be scoped to that workspace's owning
  principal rather than the caller's own creator-scoped rows.
- **persona-update-is-the-rename**: the update operation MUST send the full persona payload
  (including `slug`) on every update; a changed `slug` IS the rename — the server derives the new
  rdid and cascades it onto the handle and every descendant, and callers MUST read the new `id`
  from the echoed response rather than compute one client-side.
- **persona-by-slug-owner-lookup**: looking a persona up by slug as its owner MUST query with an
  equality filter on `slug`, take the first matching row, and MUST throw a not-found error when no
  row is returned.
- **persona-draft-narrows-visibility**: converting a persona into an editable draft MUST narrow its
  loosely-typed `visibility` string to exactly `"public" | "hub" | "private"`, defaulting any
  other stored value to `"private"`.
- **persona-fields-single-source-of-truth**: a single field table MUST describe every draft key
  exactly once, enforced by an exhaustiveness check, and deriving a blank draft or a create/update
  payload MUST derive solely from that table.
- **persona-to-body-wire-strategies**: converting a draft to a create/update payload MUST apply
  exactly the wire strategy each field declares: `"omit"` fields (e.g. `id`, `serviceName`) MUST
  NOT appear in the payload; `"trimRequired"` fields MUST be trimmed and default to `""` when
  absent; `"trimOptional"` fields MUST be trimmed and omitted entirely (never sent as `""`) when
  blank; `"raw"` fields MUST pass through untrimmed and unfiltered.
- **persona-blank-chat-status-is-independent-copy**: a blank draft MUST give `chatStatus` its own
  deep copy of the blank chat-status value, not a shared reference, so mutating one draft's rows
  MUST NOT affect another draft's.

### Demo-chat eligibility and preview

- **can-demo-chat-requires-enabled-and-line**: the demo-eligibility check MUST return `true` only
  for a well-formed object with `enabled === true`, a parsing `pacing` block (or none), and at
  least one of the keyword script or the ink script both parsing AND having a line it can actually
  say; it MUST return `false` for any other input, including non-objects, `null`, and `undefined`.
- **can-demo-chat-never-compiles-ink**: the ink check MUST test only for a non-blank `source`
  string (and an optional string `signInLine`) and MUST NOT compile or otherwise validate the ink
  script's syntax — a script with a syntax error still counts as demoable.
- **can-demo-chat-malformed-sinks-whole-config**: when either the keyword script or the ink slice
  is present but malformed, the demo-eligibility check MUST return `false` even if the other
  engine would otherwise qualify.
- **demo-preview-is-server-side-only**: the client MUST NOT implement ink replay, keyword
  matching, or escalation logic itself; the demo-preview operation MUST send the draft `source`
  and optional `signInLine`/`message`/`history`/`canEscalate` to `POST /api/persona/demo-preview`
  and MUST render only what the server returns.
- **demo-preview-history-cap-not-truncated**: callers MUST NOT truncate a `history` longer than
  the maximum preview-history length (twice the maximum preview turns = 80 entries) before
  sending — the server rejects an over-length history with a 400 rather than accepting a
  truncated one, since truncating would silently replay a different point in the script.
- **demo-preview-omitted-message-lints-and-plays-opening**: calling the demo-preview operation
  with no `message` and no `history` MUST be treated as "lint the draft and show its opening,"
  using the same call path the editor's compile check and the visitor's first turn both use.

### Chat status resolution

- **parse-chat-status-drops-not-substitutes**: parsing a chat-status configuration MUST drop a
  malformed `words` or `icons` entry rather than substituting the built-in default, and MUST
  return an empty list (not the default rows) when the author has deliberately emptied that list;
  only a `null` or non-object raw input MUST fall back to the blank chat-status value.
- **parse-chat-status-draft-preserves-incomplete-rows**: parsing a chat-status configuration for
  editing MUST preserve a half-written word pair (one of `present`/`past` blank) and an icon set
  with zero frames, and MUST NOT trim text or drop empty tags — unlike the non-editing parse,
  which drops both.
- **resolve-chat-status-words-union-icons-exclusive**: resolving a chat-status configuration for a
  given kind MUST resolve `words` as the union of rows tagged with the requested kind and untagged
  rows, but MUST resolve `icons` as the first matching set only (tagged-for-kind, else untagged,
  else the built-in fallback). This asymmetry is deliberate and MUST NOT be changed to make icons
  union the way words do.
- **resolve-chat-status-never-throws**: resolving a chat-status configuration MUST NOT throw for
  any input, including non-object raw values, and MUST always return at least one word and one
  non-empty frame set via the fallback chain through the blank chat-status value.

### Ability, may-act, and approval grants

- **persona-approvals-server-narrows-by-persona**: listing approval requests MUST forward an
  optional `personaId` filter to the server and MUST NOT re-filter the response client-side.
- **persona-may-act-grant-kind-parameterized**: granting or revoking may-act permission MUST
  accept a `kind` of `"user"` or `"team"` and MUST route through the single kind-parameterized
  endpoint.
- **persona-tools-set-autonomy-is-per-tool**: setting a tool's autonomy MUST update a single named
  tool's `autonomous` flag and MUST leave every other granted tool's autonomy untouched.
- **persona-user-tools-is-layer-two-consent**: setting a user's allowed tools MUST replace the
  calling user's full allow-list for one persona's owner-granted tools in a single write; this
  consent layer is distinct from, and downstream of, the owner-level grants managed separately.

### Special interests and interest documents

- **special-interests-list-must-filter-by-persona**: listing special interests MUST always pass
  `personaId` as a query filter; omitting it would return every special interest the caller owns
  across all of their personas, not just this one.
- **special-interest-update-strips-immutable-fields**: updating a special interest MUST strip
  `personaId` and `bucketId` from the patch body before sending, even when the caller supplies
  them, since the server treats a `personaId` change as a 400 and always assigns `bucketId`
  itself.
- **interest-documents-act-as-persona**: every interest-document operation MUST include
  `?asType=persona&asId=<personaId>`, since the research-corpus bucket's access grant is held by
  the persona, not the calling user.
- **interest-documents-list-unpaginated**: listing interest documents MUST NOT send
  `limit`/`offset`; callers MUST understand this returns only the server-capped first page (500
  rows) of an interest's document corpus.
- **interest-documents-response-envelope-differs-by-verb**: listing interest documents MUST
  unwrap a `{ rows }` envelope, while creating/updating MUST treat the response as a bare row —
  the two shapes MUST NOT be assumed interchangeable.

