
### Boards

- **project-list-workspace-scoping**: Listing boards scoped to a workspace
  MUST pin the result to that workspace's owning principal; omitted, the
  caller sees every board their reach admits ("`workspace` pins list/create
  to the WORKSPACE'S owning principal").
- **project-list-sorted-by-name**: Listing boards MUST return them sorted by
  `name` using locale-aware comparison, never in the server's raw order
  (confirmed by `hub-domain-projects-001`).
- **project-get-null-on-not-found**: Fetching a single board by id MUST
  resolve to `null` when the backend reports it missing (404), never
  rethrow — "the UI contract is null-for-missing".
- **project-subject-lookup-first-row**: Looking up a board by its subject
  (kind, id) MUST query for that subject and return the FIRST row mapped, or
  `null` when the array is empty — the auto-provisioned subject board of one
  ecosystem or persona.
- **project-create-compacts-optionals**: Creating a board MUST send `name`
  plus only the defined optionals of `description`/`color`, omitting
  optionals that were never set.
- **project-update-preserves-explicit-null**: Updating a board MUST send an
  explicit `archivedAt: null` (un-archive) through rather than stripping it,
  while an unset field (e.g. an untouched `description`) is dropped
  (confirmed by `hub-domain-projects-004`).
- **project-key-prefix-shape**: Validating a key prefix MUST trim and
  upper-case the input, return `"A key prefix is required."` for an empty
  value, `"Use 2-8 characters: a letter, then letters or digits."` for a
  value not matching the pattern "one letter, then 1-7 more letters or
  digits", and `null` when the (trimmed, upper-cased) value is valid
  (confirmed by `hub-domain-projects-006`/`007`/`008`).
- **project-key-prefix-empty-refused-not-cleared**: An empty prefix MUST be
  refused by validation rather than treated as "clear the prefix" — "there
  is no way to un-name a project's cards once they are named".
- **project-item-noun-defaults**: A board MUST default its singular/plural
  item noun to the fixed pair `"work item"`/`"work items"` when the backend
  sends an empty or absent value, never derive a plural from a singular
  ("no client can turn \"story\" into \"stories\" reliably").
- **project-estimate-scale-default**: A board MUST default a missing
  estimate scale to `"none"` — meaning "this board does not estimate" —
  never leave it unset.
- **project-priority-scale-default**: A board MUST default a missing
  priority scale to `"standard"`, the value a backend that predates the
  column implies, matching that backend's own default.
- **project-lead-both-or-neither**: A board's lead MUST be read as a
  (kind, id) pair — both set or both `null` — treating a row carrying only
  one half as unset, because "the backend cannot write one".
- **project-health-derived-not-cached**: A board's health and its
  last-updated timestamp MUST be read exactly as the backend sends them
  (derived from the newest live status update, `null` = "nobody has
  reported yet") and this component MUST NOT compute or cache a health
  value itself.
- **project-statuses-server-ordered**: Listing a board's statuses MUST
  return the rows in the server's order (by position), never re-sorted.
- **project-labels-is-a-suggestion-list**: Reading a board's labels MUST be
  read-only and MUST be treated as a non-exhaustive vocabulary — "a card may
  carry a label that is not in it yet" — never as a closed enum a form
  validates against.
- **project-participant-remove-addressing**: Removing a participant MUST
  address the row by the participant's `(kind, participantId)` pair — the
  addressed identifier is the actor's id, NOT the participant row's own id,
  and the kind is a required parameter (confirmed by
  `hub-domain-projects-002`).
- **project-saved-views-are-shared**: A saved view MUST be treated as shared
  across every caller who can read the board — "there are no private
  views" — and its `config` MUST be passed through opaquely, decoded only by
  the feature package that owns the filter vocabulary, never interpreted
  here.

### Cards

- **work-item-list-excludes-untriaged-by-default**: Listing a board's cards
  MUST return only ACCEPTED cards (a non-null triage timestamp) unless an
  "include untriaged" option is passed, because an untriaged card "has had
  no column decision made about it" and showing it would assert a placement
  nobody made.
- **work-item-list-rank-ordered**: Listing a board's cards, and listing a
  card's children, MUST return cards in rank order as the server sends
  them, never re-sorted.
- **work-item-rank-is-opaque-byte-order**: Comparing two rank strings MUST
  use a plain less-than/greater-than comparison (never subtraction, never
  locale-aware comparison), because the backend's rank column is stored in
  byte order and the rank alphabet's characters sort in that same order
  (confirmed by `hub-domain-projects-010`/`011`: byte-order comparison
  places `"aZ"` before `"az"`, while locale-aware comparison places `"aZ"`
  after `"az"`).
- **work-item-update-clears-via-explicit-null**: Updating a card MUST send
  an explicit `null` for assignee kind/id, due date, parent id, iteration
  id, milestone id, or estimate (never stripped), while an unset field
  (e.g. an untouched title) IS stripped (confirmed by
  `hub-domain-projects-012`).
- **work-item-move-by-named-neighbor**: Moving a card MUST send a move
  target naming a sibling by id/key, never an index — the five legal shapes
  are "after this id", "before this id", "after this id and before that id"
  (between, already-ordered), "after nothing" (to the top), and "before
  nothing" (to the bottom); naming neither, or nulling both, is a 400.
- **work-item-move-null-survives-compact**: Moving a card MUST let an
  explicit "after nothing" (`{afterId: null}`) reach the request body —
  distinct from an omitted `afterId`, which means "I didn't say" —
  confirmed by `hub-domain-projects-013` (`{afterId: null, beforeId:
  undefined}` sends `{"afterId":null}`).
- **work-item-move-returns-moved-card-only**: Moving a card MUST return only
  the moved card, carrying its new rank; no sibling in the response
  changes, so a caller re-sorts the list it already holds rather than
  refetching.
- **work-item-key-derivation**: A card's item key MUST default to `""` when
  the backend omits it (an older backend, or a board with no assigned
  prefix yet), and MUST be treated as read-only — never sent back on an
  update (confirmed by `hub-domain-projects-014`/`015`).
- **work-item-estimate-null-distinct-from-zero**: A card's estimate MUST
  distinguish `null` (un-estimated) from `0` (estimated at zero); an update
  with `estimate: null` un-estimates the card.
- **work-item-relations-uniform-from-either-end**: Listing or adding a
  relation MUST describe a link from THIS card's end (an "outgoing" or
  "incoming" direction, the far card's fields joined in), and removing a
  relation MUST address the far card's id alone (no kind argument) — "a
  pair carries one relation".
- **work-item-dependency-add-returns-raw-edge**: Adding a dependency MUST
  return the raw edge (no joined title/status) — a caller refetches the
  dependency list for the joined view.

### Iterations

- **iteration-owned-by-workspace-not-project**: An iteration MUST be
  addressed only by workspace (list/create) or by its own id (everything
  else) — there is no board-scoped iteration route, because one time-box
  holds cards from every board its owner runs.
- **iteration-state-is-server-derived**: An iteration's state
  (`"upcoming"|"active"|"completed"`) MUST be read exactly as the backend
  computes it from its start/end dates and today's date; this component
  MUST NOT recompute it — "the server's \"today\" is the one every other
  client sees".
- **iteration-both-dates-required**: Creating an iteration MUST require
  both a start date and an end date — an iteration with an open end is not
  a time-box because its state could not be derived from one.
- **iteration-work-items-carry-cross-board-fields**: A card listed under an
  iteration MUST carry its board name, status name, status category,
  estimate scale, and priority scale alongside the plain card fields,
  because the list spans boards and cannot be read against a single board
  header or a single status/scale set.
- **iteration-remove-returns-unassigned-count**: Removing an iteration MUST
  return an unassigned-card count rather than the affected cards — the
  sweep is a workspace-level verb and returning the rows would report cards
  the caller may not be allowed to read.
- **iteration-remove-never-refuses**: Removing an iteration MUST NOT refuse
  when the box holds cards — "no iteration" is the backlog, an ordinary
  state, unlike a board column which every card must have one of.
- **iteration-rollover-reads-status-category**: Rolling an iteration over
  to another MUST move every card whose status category is not
  `done`/`canceled` (including `backlog`) into the target iteration or the
  backlog (`null`); a board's own column labels never affect this.
- **iteration-work-items-reach-filtered**: Unlike removal/rollover, listing
  an iteration's cards MUST be reach-filtered — a card on a board the
  caller cannot open MUST NOT appear even though the caller can see the
  cycle.

### Programs

- **program-owned-by-workspace-not-project**: A program MUST be addressed
  only by workspace (list/create) or by its own id (everything else) — no
  board-scoped program route exists.
- **program-dates-independent**: A program's start date and target date
  MUST each be independently nullable — "a standing program... has
  neither".
- **program-remove-returns-unassigned-count-never-refuses**: Removing a
  program MUST return an unassigned-board count and MUST NOT refuse — "in
  no program" is an ordinary state a board may be in.
- **program-projects-no-folded-health**: Listing a program's member boards
  MUST return each with its OWN health, never a single folded verdict —
  "three at-risk boards and one off-track board have no honest single
  colour".
- **program-projects-reach-filtered**: Listing a program's member boards
  MUST be reach-filtered, unlike removal, which is a workspace-level sweep.

### Milestones

- **milestone-owned-by-project**: A milestone MUST be addressed under its
  owning board — unlike an iteration or a program, a milestone belongs to
  ONE board, and a milestone id from another board is a 404, never a
  cross-board edit.
- **milestone-counts-derived-not-stored**: A milestone's counts MUST be
  derived by the backend on every list read and MUST NOT be computed,
  cached, or written to by this component — "moving a card writes nothing
  to the milestone".
- **milestone-counts-null-means-not-reported-here**: A `null` counts value
  (as returned by an update) MUST be read as "not reported here", never as
  "zero cards" — a caller must refetch the list rather than render a
  zeroed bar.
- **milestone-undated-sorts-last**: Listing milestones MUST return them
  ordered by target date ascending with undated ones (`targetDate: null`)
  LAST, never first.
- **milestone-progress-excludes-canceled**: Computing a milestone's
  progress MUST exclude the `canceled` status category from BOTH the
  numerator (done) and the denominator (total) — a canceled card is neither
  outstanding nor finished work.
- **milestone-progress-empty-is-zero-not-nan**: Computing a milestone's
  progress MUST return `ratio: 0` (never `NaN`) when the total is `0` — "an
  empty milestone has not been achieved, it has not been populated".
- **milestone-progress-null-when-counts-absent**: Computing a milestone's
  progress MUST return `null` (never a zeroed object) when its counts are
  `null`.
- **milestone-remove-returns-unassigned-count-never-refuses**: Removing a
  milestone MUST return an unassigned-card count and MUST NOT refuse when
  the milestone has cards — "counts toward no milestone" is an ordinary
  state.

### Status Updates

- **status-update-only-writable-health-source**: Status updates MUST be the
  only writable source of a board's health — every create/update/remove of
  a report here MOVES the board's derived health.
- **status-update-list-newest-first**: Listing a board's status updates
  MUST return reports newest-first — "the first row is the one the board's
  health is read from".
- **status-update-create-requires-both-fields**: Creating a status update
  MUST require both a health value and a body — "a health with no
  explanation is a colour nobody can act on".
- **status-update-edit-gated-by-authorship**: Updating a status update MUST
  be refused (403) for anyone but the report's author, regardless of what
  verbs the caller otherwise holds — "rewriting someone else's report over
  their name is a forgery".
- **status-update-remove-rolls-health-back**: Removing the newest report
  MUST move the board's health BACK to the previous live report, or to
  `null` when none remains — "the honest outcome of withdrawing a claim".
- **status-update-caller-must-refetch-project**: A caller holding a board
  alongside its status updates MUST refetch the board after any
  create/update/remove of a report, rather than patching a health value it
  never owned.

### Templates

- **template-owned-by-workspace-not-board**: A template MUST be addressed
  only by workspace (list/create) or by its own id (everything else) — a
  template pinned to one board could only ever rebuild that board.
- **template-body-validated-strictly-against-kind**: The backend MUST
  reject (400) a stored body carrying an unrecognized key for its kind,
  rather than silently discarding it — "a discarded key in a template is a
  step of a checklist that quietly stopped existing".
- **template-body-narrowing-never-throws**: Narrowing a template's stored
  body to a card-shaped or board-shaped body MUST return `null` (never
  throw) for a template of the other kind, so a renderer handed a mixed
  list can skip what it cannot draw.
- **template-card-count-is-a-preview-not-a-promise**: Reading a card-shaped
  template's card count MUST read "1 plus its children count" from the
  STORED body, `0` for a board-shaped template — a preview, not a
  guarantee.
- **template-update-body-replaces-not-merges**: Updating a template's body
  MUST replace the whole stored shape, never merge into it — "merging would
  leave no way to delete a checklist step".
- **template-update-cannot-rekind**: Updating a template MUST NOT carry a
  kind field — re-kinding would re-read a stored body against a schema it
  was never written for.
- **template-remove-is-non-cascading**: Removing a template MUST NOT touch
  anything the template previously made — "ordinary rows that stopped
  being related to it the moment they were written".
- **template-instantiate-work-item-title-scoped-to-parent**: A title
  supplied when instantiating a card-shaped template MUST re-title only the
  parent card, never its children — "renaming a checklist's steps at
  instantiation is editing the template, not using it".
- **template-instantiate-project-milestones-undated**: Instantiating a
  board-shaped template MUST return milestones UNDATED, in the template
  body's order — seeding a stored date would hand back a plan already
  overdue.

### Triage

- **triage-membership-is-a-timestamp**: A card MUST be considered "in
  triage" exactly when its triage timestamp is `null`; this is the entire
  membership rule — no separate status enum exists for it.
- **triage-opt-in-via-create-flag**: A card MUST land in the triage queue
  only when a "triage" flag is passed on creation; a board that never
  passes it has an unchanged, always-empty inbox.
- **triage-no-decline-verb**: There MUST be no "decline" method or
  parameter; declining a card is expressed as accepting it into a status in
  the `canceled` category — "leaves the card findable and says what
  happened to it".
- **triage-accept-idempotent-on-stamp**: Accepting an already-accepted card
  MUST apply the given placement but MUST leave the original triage
  timestamp unchanged — "a double-click must not rewrite it".
- **triage-list-for-project-vs-cross-board-partition**: Listing a single
  board's triage queue (full cards) and listing its accepted cards MUST
  partition the board's cards exactly — every card is in exactly one of the
  two lists unless "include untriaged" is passed to the latter.
- **triage-cross-board-signpost-carries-owning-prefix**: A cross-board
  triage hit's item key MUST already be rendered against the OWNING
  board's prefix (or `""` when that board has none) — the cross-board
  caller has no prefix of its own to render it with.
- **triage-cross-board-limit-is-clamped-and-exact**: Listing the
  cross-board triage queue's returned page limit MUST be the value the
  server actually applied (it clamps 1..200, default 50, rather than
  refusing), and its "has more" flag MUST be computed by the server
  over-fetching one row, so it is exact.

### Search

- **search-blank-query-short-circuits**: Searching cards MUST return an
  empty result without issuing a network call when the query, trimmed, is
  empty — "an empty search box is the ordinary state of a search box, not
  an error to render" (confirmed by `hub-domain-projects-018`).
- **search-query-trimmed-before-send**: A query with leading/trailing
  whitespace MUST be trimmed before it is sent, so trailing whitespace is
  never a different search from its trimmed form (confirmed by
  `hub-domain-projects-019`).
- **search-optional-params-omitted-when-unset**: The workspace and limit
  parameters MUST be OMITTED from the query when unset, never sent empty —
  an empty workspace value is fail-closed on the server, so an empty slug
  and no slug must not mean the same thing on the wire (confirmed by
  `hub-domain-projects-020`).
- **search-result-order-is-servers**: The returned page's results order
  MUST be the server's own (a keyed hit first, then rank, then recency);
  this component MUST NOT re-sort by rank — "a client holding one page
  cannot rank a result set it only partly has" (confirmed by
  `hub-domain-projects-021`).
- **search-echoed-limit-may-differ-from-requested**: The returned page's
  limit MUST be read from the server's response, never assumed equal to
  the requested limit — the server clamps rather than refusing an
  out-of-range value (confirmed by `hub-domain-projects-021`).
- **search-hit-defaults-snippet-and-rank**: A search hit MUST default a
  missing snippet to `""` and a missing rank to `0`, never leave either
  unset (confirmed by `hub-domain-projects-022`).
- **search-is-not-an-in-board-filter**: This component MUST NOT be used for
  an in-board text filter — a board's own list is already loaded and
  filtered locally; this reaches across boards the caller has not loaded.

### Activity

- **activity-newest-first-keyset-paginated**: Both board-level and
  card-level activity MUST page newest-first using a `{ limit?, before? }`
  keyset.
- **activity-before-token-is-opaque-composite**: The "before" cursor MUST be
  treated as opaque by callers and, internally, MUST be split on the LAST
  `"|"` into a timestamp and an id for the backend's composite keyset, so
  millisecond-tied rows never straddle a page boundary (confirmed by
  `hub-domain-projects-023`).
- **activity-legacy-token-without-id-still-works**: A "before" token with no
  `"|"` (a legacy token) MUST still send the timestamp alone, with no id.
- **activity-next-before-full-page-heuristic**: The "next before" token MUST
  be the last row's composite `"<createdAt>|<id>"` token when the returned
  page's length equals the requested limit (implying more may exist), and
  `null` otherwise (a short/last page, or no limit given at all) (confirmed
  by `hub-domain-projects-023`/`024`).
- **activity-writes-live-elsewhere**: Writing a comment MUST NOT go through
  this component — the comments grouping owns the write, and the resulting
  "comment added/edited/deleted" action still appears in this trail because
  the backend writes both in one transaction.

### Comments

- **comment-list-oldest-first**: Listing a card's comments MUST return them
  in the server's oldest-first order and MUST NOT re-sort them — "a
  conversation only reads correctly forward" (confirmed by
  `hub-domain-projects-025`).
- **comment-threading-one-level-deep**: Threading comments MUST group a
  flat, oldest-first list into root/reply pairs with no recursion, because
  the backend already re-parents a reply-to-a-reply onto the root
  (confirmed by `hub-domain-projects-026`).
- **comment-orphan-promoted-not-dropped**: Threading comments MUST promote a
  reply whose parent id is not present in the list to a root of its own,
  appended after the real roots, rather than dropping it — "the parent was
  removed while this reply stands" (confirmed by `hub-domain-projects-027`).
- **comment-author-kind-unknown-falls-back-to-customer**: Reading a comment
  MUST map an unrecognized author-kind string to `"customer"` — "the
  reading that claims the least", never a synthetic value that could pose
  as an agent (confirmed by `hub-domain-projects-028`).
- **comment-edit-gated-by-authorship**: Editing a comment MUST be refused
  by the backend for anyone but the comment's author — "an editing verb on
  the board does not let a moderator put words in someone's mouth".
- **comment-remove-leaves-replies-standing**: Removing a comment MUST leave
  any replies to it in place — "a thread does not lose its answers along
  with its question".
- **comment-add-omits-parent-id-for-top-level**: Adding a top-level comment
  (no parent given) MUST send a body with no parent-id key at all, never an
  explicitly unset one serialized (confirmed by `hub-domain-projects-025`).
- **comment-reaction-kind-is-a-named-constant**: The comment reaction kind
  (`"project.comments"`) MUST be the single spelling every reaction call
  site uses, never a literal restated at each site — comments are reacted
  to through the shared polymorphic (target kind, target id) reaction
  store, not a comments-owned endpoint.

### Artifacts

- **artifact-link-id-distinct-from-target-id**: An artifact link's id MUST
  identify the LINK (what unlinking addresses), never the target — the
  same target can be linked twice (once "ingested", once "produced"), so
  the target id alone does not identify a row (confirmed by
  `hub-domain-projects-029`).
- **artifact-link-idempotent-per-triple**: Linking an artifact (direction,
  target kind, target id) MUST be idempotent per that triple — re-linking
  the same triple MUST return the existing row rather than create a
  duplicate — "a double-click cannot litter the list".
- **artifact-unresolvable-target-kept-as-null**: An artifact link whose
  target no longer resolves MUST be returned with a `null` target and its
  target kind/id intact, never dropped from the list — "the link is still
  a fact about the board" (confirmed by `hub-domain-projects-029`).
- **artifact-list-server-order-preserved**: Listing a board's artifact links
  MUST preserve the server's (newest-first) order, never re-sort — a
  client re-sort "would silently disagree with the pagination the endpoint
  is built for" (confirmed by `hub-domain-projects-029`).
- **artifact-attachable-limit-is-per-kind**: The attachable-picker's limit
  option MUST be understood as per-KIND, not per-response, so one kind
  cannot crowd the others out of the picker.
- **artifact-kind-vocabulary-is-backend-owned**: This component MUST NOT
  define or hard-code a list of valid target-kind values — the attachable
  picker is how a picker discovers what a board can hold, and a deployed
  client picks up a newly added kind on its next request without a code
  change.
- **artifact-unlink-addresses-link-not-target**: Unlinking an artifact MUST
  address the LINK's id; the target itself is untouched — "this removes
  the board's claim on it, never the thing" (confirmed by
  `hub-domain-projects-030`).

### Live Wake

- **live-payload-less-wake**: The board's live-change event MUST carry no
  payload and no change kind; the wake callback MUST take no arguments
  describing what changed — every subscriber re-reads through its own
  ordinary request under the access rules it already passes.
- **live-one-connection-per-board-refcounted**: Subscribing to a board's
  live wake MUST open exactly ONE underlying connection per distinct board
  id, shared by every subscriber, and MUST close it only when the LAST
  subscriber unsubscribes (confirmed by `hub-domain-projects-031`/`033`).
- **live-reopens-after-going-quiet**: Re-subscribing to a board after its
  connection was fully closed MUST open a fresh connection, never reuse
  the closed handle (confirmed by `hub-domain-projects-034`).
- **live-coalesces-burst-into-one-wake**: A burst of same-board live-change
  events within a 150ms trailing coalescing window MUST fold into exactly
  one wake call per subscriber, never one call per event (confirmed by
  `hub-domain-projects-035`).
- **live-wakes-again-after-window-closes**: The coalescing guard MUST be a
  window, not a once-per-connection latch — a change arriving after a
  previous window already fired MUST produce a second wake call (confirmed
  by `hub-domain-projects-036`).
- **live-poll-fallback-wakes-identically**: A polling fallback MUST wake
  subscribers exactly as a live event does, at a 60,000ms cadence, so a
  board with no live connection still updates each session (confirmed by
  `hub-domain-projects-037`).
- **live-unsubscribe-during-pending-wake-is-silent**: A subscriber that
  unsubscribes while a coalesced wake is pending MUST NOT receive that wake
  — the listener set is snapshotted at fire time (confirmed by
  `hub-domain-projects-038`/`039`).
- **live-last-unsubscribe-drops-pending-timer**: When the LAST subscriber of
  a board unsubscribes while a wake timer is pending, unsubscribing MUST
  clear that timer and close the connection, rather than letting a stale
  timer fire against a torn-down entry (confirmed by
  `hub-domain-projects-039`).
- **live-onwake-read-at-fire-time-not-closed-over**: The live-wake
  consuming hook MUST hold the latest wake callback and read it at fire
  time, rather than treating its identity as significant — a caller whose
  wake callback identity changes every render (a filter edit) MUST NOT
  tear down and reopen the shared connection on every keystroke.
- **live-null-project-id-subscribes-to-nothing**: The live-wake consuming
  hook, given no board id, MUST subscribe to nothing, so a pane may call
  it before its board has resolved.

