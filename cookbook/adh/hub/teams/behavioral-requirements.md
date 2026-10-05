
### Team client

- **team-vocabulary-mapping**: Mapping a backend team row to its UI shape
  MUST map the row's `name` column to the UI's `displayName` field and
  `slug` to the UI's `identifier` field, passing `id`, `createdAt`, and
  `updatedAt` through unchanged.
- **team-identifier-is-reverse-domain**: A team's `identifier` MUST be a
  reverse-domain string, e.g. `com.example.platform`.
- **identifier-validation-empty-refused**: Validating a team identifier
  MUST return `"Identifier is required."` for an empty identifier, checked
  before the shape rule.
- **identifier-validation-shape**: Validating a team identifier MUST
  return `"Use reverse-domain form, e.g. com.example.platform."` for a
  non-empty identifier that fails the pattern one lowercase-alphanumeric
  label followed by one or more dot-separated lowercase-alphanumeric-or-
  hyphen labels, and MUST return `null` when the identifier passes.
- **team-list-scoped-to-ecosystem**: Listing teams for an ecosystem MUST
  send `GET /api/team/teams?ecosystemId=<encoded ecosystemId>`; the
  backend then returns ONLY that ecosystem's teams, enforced even for an
  admin caller.
- **team-list-sorted-by-display-name**: Listing teams MUST return teams
  sorted by `displayName` via a locale-aware text comparison, never in the
  backend's raw row order.
- **team-get-resolves-null-on-thrown-error**: Fetching a single team by id
  MUST resolve to `null` rather than rethrow when the underlying request
  throws — the backend responds 404 with a thrown error; the UI contract
  is null-for-missing.
- **team-get-swallows-any-error-as-not-found**: Fetching a single team by id MUST resolve to
  `null` for ANY thrown error, not only the backend's documented 404, so a network failure or a
  server error is indistinguishable from a team that genuinely does not exist, and no signal (a
  rethrow, a log call) reaches the caller to tell the two apart.
- **team-create-no-pre-read-relies-on-backend-constraint**: Creating a
  team MUST NOT pre-read for a duplicate identifier before submitting the
  create — the backend's unique owner/slug constraint is the sole guard,
  because a pre-read can't see a soft-deleted row still holding the slug.
- **team-create-scopes-into-ecosystem**: Creating a team MUST send the
  create request to `/api/team/teams?ecosystemId=<encoded ecosystemId>`,
  stamping the new team into that ecosystem so it lands in — and is
  visible under — the workspace it was created in.
- **team-create-conflict-rethrown-friendly**: On a conflict response whose
  message matches "already exists" (case-insensitive), creating a team
  MUST rethrow via the shared conflict-translation helper as `A team with
  identifier "<identifier>" already exists.`; any other error MUST
  rethrow unchanged.
- **team-update-partial-via-compact**: Updating a team MUST send only the
  defined optional keys of `{name, slug}` through the shared
  field-compaction helper — an omitted (unset) field MUST be dropped from
  the update body.
- **team-update-conflict-rethrown-friendly**: Updating a team MUST
  rethrow a conflict response for a slug collision via the shared
  conflict-translation helper with the same friendly-message shape as
  creating a team, because a slug rename can collide with the unique
  owner/slug index.
- **team-delete-issues-delete**: Deleting a team MUST send `DELETE
  /api/team/teams/<encoded id>` and resolve with no value on success.
- **team-row-id-is-opaque**: A team's `id` MUST be treated as an opaque,
  server-generated identifier, never derived or parsed by this client.

### Team-membership client

- **member-kind-discriminates-customer-vs-persona**: A member's
  `memberKind` MUST be read as `"customer"` for any value other than the
  literal `"persona"` — present on every listing row; treat anything other
  than `"persona"` as a customer (robust to the field still being optional
  in the wire shape).
- **member-email-null-outside-ecosystem**: A member's `email` MUST be
  `null` when the member's customer row lies outside the caller's
  ecosystem, and MUST be non-null only when resolved from a customer row
  within it.
- **member-persona-fields-null-for-customers**: A member's `personaSlug`
  and `personaName` MUST be set only for a persona member and MUST be
  `null` for a customer member.
- **member-list-tolerates-missing-members-key**: Listing members MUST
  return an empty array when the response body carries no `members` key,
  rather than dereferencing an absent value — tolerating a body without
  `members` (the route always sends it, but a proxy/error page might not).
- **member-list-query-scoped-by-team**: Listing members for a team MUST
  send `GET /api/team/members?teamId=<encoded teamId>`.
- **member-counts-maps-team-to-count**: Fetching member counts MUST return
  a map keyed by team id to that team's member count within the caller's
  scope, built from `GET /api/team/members/counts`, and MUST default to an
  empty map when the response carries no `counts` array.
- **member-counts-is-unreferenced-but-retained**: Fetching member counts
  MUST remain in this client even though nothing in the fleet calls it
  now — the backend route it wraps is live, and this client mirrors the
  backend's surface, not the current callers'; it MUST be deleted only
  together with the route it wraps, never before.
- **member-add-by-email-resolves-existing-customer**: Adding a member by
  email MUST send a create request with `{teamId, email}` to
  `/api/team/members`, adding an EXISTING customer resolved by email
  within the caller's ecosystem — never creating a new customer; the
  backend responds 404 when none resolves.
- **member-add-persona-gated-by-may-act**: Adding a member by persona key
  MUST send a create request with `{teamId, personaKey}` to
  `/api/team/members/personas`, and the backend MUST refuse the call (403)
  unless the named persona has been granted the "team" action-permission.
- **member-remove-addresses-member-row**: Removing a member MUST send
  `DELETE /api/team/members/<encoded memberId>`, addressing the MEMBER
  row's own id — not the team id, nor the underlying user's or persona's
  id.
- **member-errors-propagate-with-backend-message**: Listing members,
  fetching counts, adding a member by email, adding a member by persona,
  and removing a member MUST NOT catch or transform a thrown error — the
  shared request helper throws an error carrying the backend's message
  verbatim, and every method here lets it propagate unchanged so callers
  surface that message inline.
- **member-add-duplicate-is-conflict**: Adding a member already on the
  team MUST surface as a thrown error from a backend conflict response —
  the backend guards duplicates; this client performs no client-side
  pre-check for this, unlike the team client's create/update
  friendly-message mapping.
- **member-types-hand-declared-off-openapi**: A member record and its
  request bodies MUST be maintained by hand in this client rather than
  generated, because the membership route is off the generated OpenAPI
  surface.

### Shared wire shapes

- **wire-types-mirror-call-sites-only**: The backend row and request-body
  shapes MUST carry exactly the fields the team client's mappers and call
  sites touch, replacing the hub's generated success/request-body
  wrappers so this client does not inherit "adh product vocabulary a
  generic data client must not take on."
- **team-put-body-is-fully-partial**: The update-request body's `name` and
  `slug` MUST both be optional, matching the generic-CRUD backend's
  partial-schema PUT contract.

