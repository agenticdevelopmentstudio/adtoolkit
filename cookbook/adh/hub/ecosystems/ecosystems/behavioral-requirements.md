
### Ecosystem record

- **ecosystem-model-shape**: An ecosystem record MUST carry `id`, `slug`,
  `name`, an optional `description`, an optional `region`, an optional
  primary domain, optional `createdAt`/`updatedAt` timestamps, `isDefault`,
  an optional `isInfrastructure` flag, an optional `parentId`, and an
  optional `canManage` flag.
- **ecosystem-decode-default-fallback**: Building an ecosystem record from a
  server payload MUST treat a missing `isDefault` field as `false` rather
  than failing to parse.
- **ecosystem-identifier-prefix**: An ecosystem's identifier prefix MUST be
  everything up to and including the last `.` in its id (e.g. `"org.acme."`
  for `"org.acme.shop"`), and MUST be `""` when the id contains no `.`.
- **ecosystem-is-manageable**: Whether an ecosystem is manageable MUST equal
  its `canManage` flag, treating an absent flag (the server omits it for the
  caller's own ecosystems) as manageable — only an explicit `false` blocks
  descending into it.
- **ecosystem-create-input-defaults**: Creating an ecosystem MUST default
  `region` and the primary domain to `""` when the caller omits them.
- **ecosystem-update-input-shape**: Updating an ecosystem MUST accept every
  field (`slug`, `name`, `description`, `region`, primary domain) as
  optional, so a caller can patch a subset.
- **address-leaf-extraction**: Extracting an address's leaf segment from an
  identifier MUST return everything after the last `.` — a pure string
  slice with no rdid-grammar validation, deliberately mirroring the
  backend's own leaf extraction character for character.
- **to-ecosystem-field-mapping**: Mapping a stored ecosystem row into the
  ecosystem record MUST map the row's id to both the record's id and
  identifier, its slug to slug, its nullable description/region columns to
  `""` when absent, its primary-domain column to the record's domain field
  (`""` when absent), and MUST include `canManage` in the result only when
  the row itself defines it — never as an explicit absent-marker value.

### Data access boundary

- **ecosystems-data-source-contract**: The ecosystems data-access boundary
  MUST expose exactly: list, children-of-a-parent, get-by-id,
  infrastructure-id, identifier-exists, create, update, and delete
  operations, each of which may fail.
- **ecosystems-list-includes-defaults**: The list operation's own contract
  MUST hold that it includes default rows — hiding `isDefault` rows is the
  root listing's job, not the data-access boundary's.

### Root listing and rail navigation

- **root-level-hides-defaults**: The root listing MUST filter out every
  `ecosystem.isDefault == true` row before building items.
- **root-level-shape**: The root listing MUST have id `"ecosystems"`, title
  `"Products"`, empty message `"No products yet."`, and a create action
  titled `"New Product"` that presents the create form for a new, parentless
  ecosystem.
- **root-level-errors-wrap**: Fetching the root listing MUST surface any
  failure from the underlying list call as a domain error rather than
  letting through whatever error shape the call itself raised.
- **ecosystem-item-shape**: An ecosystem's rail item MUST use the
  ecosystem's id as both its id and sublabel, the ecosystem's name as its
  label, and a shipping-box icon.
- **child-by-id-not-found-is-empty**: Resolving an ecosystem by id for the
  rail MUST return an empty result when that resolution reports not-found,
  and MUST surface any other failure as a domain error.
- **child-manageability-gate-first**: Descending into an ecosystem MUST
  check whether it is manageable BEFORE resolving any topic — an
  unmanageable ecosystem MUST return a notice detail (id
  `"ecosystem:<id>:not-manageable"`, the fixed not-manageable title and
  message) regardless of what path segment follows.
- **not-manageable-copy**: The not-manageable notice's title MUST be
  `"You don't have admin access to this ecosystem"` and its message MUST be
  `"Viewing an ecosystem's contents needs organization admin access — ask
  one of the organization's admins."`
- **topics-level-shape**: With no further path segment, descending into an
  ecosystem MUST return a list with id `"ecosystem-topics"`, title equal to
  the ecosystem's name, and items built from the topic set in the order the
  caller supplied it — the rail MUST NOT impose a fixed topic order of its
  own.
- **topic-dispatch-by-entry-id**: With a topic-id path segment, descending
  into an ecosystem MUST look up the matching topic by its entry id and
  return an empty result when none matches, else delegate to that topic.

### Topic composition

- **topic-entry-to-item**: A topic entry converted to a rail item MUST carry
  its id, label, sublabel equal to its description, icon, divider-after
  flag, and its destination (defaulting to a list).
- **topic-group-level-shape**: With no further path segment, a topic group
  MUST return a list with id `"ecosystem-group:<entry id>"`, title equal to
  the entry's label, and its children mapped to items; with a segment, it
  MUST delegate to the matching child by entry id or return an empty result.
- **notice-topic-detail-shape**: A notice topic MUST always return a detail
  view with id `"ecosystem:<ecosystem id>:<entry id>"`, title equal to the
  entry's label, and the fixed message it was constructed with — it MUST
  NOT branch on the remaining path.

### Creating an ecosystem

- **create-form-fields**: The create form MUST define exactly three fields,
  in order: `name` (text, required), `slug` (text, required, matching the
  slug pattern, with the associated validation message), `description`
  (text area, optional, at least 3 lines).
- **create-form-slug-lowercased**: The save action MUST lowercase the
  submitted slug before deriving the identifier or probing for existence,
  independent of the field validator's own pattern check.
- **create-form-slug-max-length**: The save action MUST reject the save
  with a validation error reading `"Slug must be 64 characters or fewer."`
  when the lowercased slug exceeds 64 characters.
- **create-form-prefix-resolution**: The save action MUST use the parent
  ecosystem's id as the address prefix when a parent was supplied at
  construction, and MUST otherwise resolve the caller's infrastructure id
  for the prefix, surfacing any failure from that resolution as a domain
  error.
- **create-form-identifier-derivation**: The derived identifier MUST be
  exactly `"<prefix>.<slug>"`.
- **create-form-duplicate-probe**: Before creating, the save action MUST
  probe whether the derived identifier already exists and reject the save
  with a validation error reading `Identifier "<identifier>" is already in
  use.` when it does, without ever issuing the create call.
- **create-form-conflict-mapping**: A conflict raised by the create call
  MUST be re-surfaced as a validation error reading `An ecosystem with
  identifier "<identifier>" already exists.`; any other failure MUST be
  surfaced as a domain error.
- **create-body-shape**: Creating an ecosystem over the wire MUST send the
  identifier as `id` and the address's last segment (never the whole dotted
  identifier) as `slug`, plus `name`, `description`, `region`, and the
  primary domain.
- **create-scoping-url**: A create request MUST scope to a parent when one
  is given, else to a workspace when one is given, else use the bare base
  route; a given parent MUST win when both are supplied.
- **create-conflict-mapping**: A conflict from the create request MUST be
  surfaced with the message `An ecosystem with identifier "<identifier>"
  already exists.`

### Ecosystem settings

- **settings-form-fields**: The settings form MUST define, in order: `name`
  (text), `slug` (text, matching the slug pattern), `id` (read-only,
  monospaced, labeled `"Identifier"`), `description` (text area), `region`
  (read-only, labeled `"Geographic Region"`).
- **settings-values-region-hardcoded**: The settings form's values MUST
  report `region` as the literal string `"coming soon"` regardless of the
  ecosystem's own region value.
- **settings-save-identifier-derivation**: The save action MUST derive the
  target identifier as the ecosystem's identifier prefix plus the
  lowercased submitted slug, never from the form's read-only `id` field.
- **settings-save-slug-lowercased**: The save action MUST lowercase the
  submitted slug before deriving the identifier, independent of the field
  validator's own pattern check.
- **settings-save-slug-validation**: The save action MUST validate the
  lowercased slug against the slug pattern and reject the save with a
  validation error naming the derived identifier and describing the
  allowed character set when it fails.
- **settings-save-excludes-region**: The update the save action sends MUST
  carry only `slug`, `name`, and `description` — it MUST NOT set `region`
  or the primary domain, even though the form displays a region value.
- **settings-save-conflict-mapping**: A conflict raised by the update call
  MUST be re-surfaced as a validation error reading `Identifier
  "<identifier>" is already in use.`; any other failure MUST be surfaced as
  a domain error.
- **settings-delete-action**: The settings form's delete action MUST be
  titled `"Delete Product"` with the fixed confirmation warning, and MUST
  call the delete operation for the ecosystem's id, surfacing any failure
  as a domain error.

### Reading, listing, and updating an ecosystem over the wire

- **list-hides-defaults-sorted**: The list operation MUST filter out every
  `isDefault === true` row and sort the remainder by name, locale-aware.
- **list-for-workspace-scoped**: Listing scoped to a workspace MUST request
  that workspace's scope and sort by name; it MUST NOT client-filter
  `isDefault`, since the server already excludes both structural defaults
  and the principal's own infrastructure row for this scope.
- **list-children-scoped**: Listing an ecosystem's children MUST request
  that parent's scope and sort by name.
- **get-404-is-null**: Getting an ecosystem by id MUST return `null` when
  the request fails with not-found, and MUST rethrow any other failure
  unchanged.
- **update-slug-sent-on-presence**: Updating an ecosystem MUST send the
  address's last segment as `slug` whenever an identifier is supplied —
  including when the submitted identifier equals the stored id — and MUST
  NOT diff the submitted identifier against the stored id to decide whether
  to send it, because the stored id is the handle, not the address the row
  currently derives to, and the two can disagree on a drifted row.
- **update-omits-unset-fields**: The update's body MUST omit any field the
  caller did not supply (including `slug` when no identifier is supplied)
  entirely, never sending it as an explicit absent-marker value.
- **update-single-put**: An update MUST be exactly one write request — it
  MUST NOT follow up with a second call to rename a handle.
- **update-returns-server-derived-row**: An update's resolved ecosystem
  record MUST reflect the address the server derived from the write, never
  the identifier the caller typed, since a malformed or stale prefix in the
  caller's identifier can derive to a different address than what the
  caller assumed.
- **delete-no-body**: Deleting an ecosystem MUST send a delete request with
  no body and resolve with no value.
- **auth-settings-bespoke-routes**: Reading and updating an ecosystem's auth
  settings MUST use their own dedicated route rather than the generic
  ecosystems create/read/update/delete base.

### Child ecosystems

- **child-ecosystems-list-shape**: With no further path segment, descending
  into "child ecosystems" MUST return a list with id
  `"child-ecosystems-list"`, title equal to the entry's label (`"Child
  Ecosystems"`), empty message `"No child ecosystems yet."`, and a create
  action titled `"New Ecosystem"` that presents the create form scoped to
  this ecosystem as parent.
- **child-ecosystems-descend-not-found-empty**: Resolving a child by id
  MUST return an empty result when that resolution reports not-found, and
  MUST surface any other failure as a domain error.
- **child-ecosystems-recurse-via-rail**: Once a child ecosystem resolves,
  its remaining path MUST be delegated back to the same rail rather than
  resolved locally — this is what lets an arbitrarily deep chain of child
  ecosystems reuse the exact same rail (manageability gate, topic dispatch,
  settings, further child ecosystems) at every level.

### Identifier rename and slug ownership

- **identifier-exists-never-404s**: The identifier-existence probe MUST
  return its boolean result directly — it MUST NOT itself fail for an
  identifier that is not taken.
- **identifier-rename-conflict-mapping**: Renaming an identifier MUST
  request the change and MUST surface a conflict with the message `The
  identifier "<next identifier>" is already in use.`
- **identifier-rename-is-not-ecosystems-renaming-route**: The generic,
  entity-agnostic identifier-rename mechanism (shared across
  ecosystem/application/persona/namespace/organization) MUST NOT be used to
  rename an ecosystem's address — the ecosystem update call that carries
  `slug` is the correct route for that, per **update-slug-sent-on-presence**.
- **ecosystem-id-for-slug-ownership-first**: Resolving an ecosystem id for a
  slug MUST first try to resolve the caller's own workspace-scoped default
  for that slug; on any failure other than not-found, it MUST rethrow
  without falling back to a scan; when that resolution finds a row it MUST
  return that row's id; only a not-found (the slug names no workspace) or a
  resolved empty answer (no infrastructure row) MUST license a fallback raw
  scan of the unfiltered base list, returning the first row matching the
  slug, else the first default row, else the first row, else nothing.
- **workspace-default-ecosystem-id-shape**: Resolving the workspace default
  ecosystem id MUST scope the request to the given workspace and to the
  caller's infrastructure row when a workspace is given, else scope to the
  caller's own infrastructure row; it MUST return nothing (never an
  undefined/absent-marker value) when the response is an empty list; and it
  MUST return `canManage` as `true` unless the row explicitly says `false`.

### Workspace default resolution (query state)

- **workspace-default-hook-always-enabled**: The workspace-default-ecosystem
  query MUST NOT be disabled on the workspace slug being defined — it MUST
  always run, resolving the caller's own row when no slug is given.
- **workspace-default-hook-query-key**: The query's cache key MUST include
  the tenant id and the workspace slug (or an explicit absent marker when
  none is given), so the cache entry is scoped per tenant and per slug.
- **workspace-default-hook-shared-client**: The query MUST use one
  module-scoped shared query client explicitly rather than a client from
  ambient context, so the cache entry is shared platform-wide across every
  mounting host.
- **workspace-default-hook-result-shape**: The query's result MUST expose
  the resolved ecosystem id (or nothing), `canManage` (defaulting to
  `true`), whether it errored, whether no answer has arrived yet (distinct
  from a resolved-but-empty answer), and whether a read is currently in
  flight.
- **workspace-default-hook-no-retry**: The query MUST be configured not to
  retry automatically on failure.

### Invitations topic data

- **eco-invitations-keys-namespaced-by-rdid**: Every cache key for the
  Invitations topic MUST include the ecosystem's rdid as its second
  element, so two ecosystems' Invitations caches never collide.
- **eco-invitations-list-hooks-map-rows**: The requests, pending-users, and
  invites list queries MUST fetch from the matching Invitations endpoint
  for the ecosystem and map every row through the shared row mappers
  before returning them.
- **eco-invitations-notes-history-gated-on-subject**: The row-notes and
  row-history queries MUST be disabled while no subject id is given —
  neither query may run for an empty subject id.
- **eco-invitations-save-notes-invalidates-notes-and-history**: Saving
  notes, on success, MUST invalidate both the matching notes cache entry
  and the matching history cache entry for the same subject.
- **eco-invitations-send-invalidates-pending-and-invites**: Sending
  invitations, on success, MUST invalidate both the pending-users cache
  entry and the invites cache entry for the ecosystem.
- **eco-invitations-add-pending-invalidates-pending**: Adding pending
  users, on success, MUST invalidate the pending-users cache entry.
- **eco-invitations-delete-row-dispatch**: Deleting an Invitations row MUST
  select the matching delete endpoint by the row's kind, and on success
  MUST invalidate exactly the one list cache entry matching that same kind.

### Feature provisioning — catalog and state

- **features-bespoke-route**: Every feature-picker call MUST target its own
  dedicated route, never the generic ecosystems create/read/update/delete
  base, because provisioning a feature has side effects on the server (its
  storage, child ecosystem, and roles are created when the feature is added
  and at no other time).
- **features-path-segments-encoded**: Listing, provisioning, and removing
  MUST URL-encode the ecosystem identifier (an rdid or opaque id) and the
  feature key before placing them in the path.
- **features-catalog-order-preserved**: Fetching the feature catalog MUST
  return the response's feature list unchanged, in the backend's own order
  — the client MUST NOT sort or filter it.
- **features-catalog-entry-shape**: A catalog entry MUST carry a stable key
  (what a provisioned row is keyed by), a label, a description, a
  subscription tier, and the optional flags for whether it has a feature
  site and whether it is coming soon.
- **features-subscription-tier-open-string**: A feature's subscription tier
  MUST be treated as an open, unconstrained value rather than a closed set,
  so a tier the backend adds later renders instead of failing to parse; the
  client MUST only display it, never branch on it.
- **features-coming-soon-passthrough**: A catalog entry marked coming-soon
  MUST be returned like any other entry — the client MUST NOT filter it
  out; it is listed so the owner can see it is coming, shown under "Coming
  soon" with its checkbox disabled, and the backend refuses to provision
  it.
- **features-list-all-states**: Listing an ecosystem's provisioned features
  MUST return every feature in every state (provisioning, active, removed)
  unfiltered — callers filter.
- **features-provisioned-shape**: A provisioned feature MUST carry its
  feature key, state, when it was provisioned, who provisioned it (or
  nothing), and when it was last updated.

### Feature provisioning — mutating and caching

- **features-provision-one-request**: Provisioning a batch of features
  MUST send exactly one request carrying the whole batch of keys, never one
  request per key.
- **features-provision-returns-full-list**: Provisioning MUST resolve to
  the ecosystem's full provisioned list after the add, not only the added
  rows.
- **features-remove-single-delete**: Removing one feature MUST send one
  delete request with no body and resolve with no value.
- **features-remove-404-is-success**: Removing a feature MUST resolve (not
  fail) when the delete fails with not-found, because the row is already
  gone.
- **features-remove-rethrows-other-errors**: Removing a feature MUST
  rethrow every other failure unchanged.
- **features-query-keys**: The catalog's cache key MUST carry no ecosystem
  id — the catalog is a property of the server build, shared by every
  ecosystem — and the provisioned-features cache key MUST include the
  ecosystem id (or an explicit empty marker).
- **features-catalog-stale-time**: The feature catalog MUST be considered
  fresh for 30 minutes (1,800,000 ms), so opening the picker again within
  that window does not refetch it.
- **features-provisioned-query-gated**: The provisioned-features query MUST
  be disabled while the ecosystem id is nothing, undefined, or empty.
- **features-hooks-context-client**: The feature queries and mutations MUST
  use the shared query client from ambient context — unlike the
  workspace-default-ecosystem query, which uses the module singleton
  explicitly.
- **features-provision-writes-cache-then-invalidates**: Provisioning, on
  success, MUST first write the returned full list into the
  provisioned-features cache entry and then invalidate that same entry, so
  a dependent view redraws on the same tick and still picks up a concurrent
  session's changes.
- **features-remove-hook-invalidates**: Removing one feature, on success,
  MUST invalidate the provisioned-features cache entry and MUST NOT write
  to the cache directly (the delete returns no list).
- **features-apply-adds-first**: Applying a batch of feature changes MUST
  await the single add request before issuing any removal, so a failed
  removal never costs the owner the features just added; a failed add MUST
  reject the whole change before any removal is sent.
- **features-apply-skips-empty-add**: Applying a batch of feature changes
  MUST NOT send an add request when there is nothing to add.
- **features-apply-removals-all-settled**: Applying a batch of feature
  changes MUST issue one removal per key to remove, concurrently, and wait
  for all of them, so one rejected removal MUST NOT prevent the others from
  being attempted.
- **features-apply-names-failed-keys**: When one or more removals fail,
  applying the change MUST reject naming the failed keys, in removal order,
  joined by a comma.
- **features-apply-404-removal-succeeds**: A removal that reports
  not-found MUST count as success, so a change whose only removal failures
  are not-found results MUST resolve.
- **features-apply-invalidates-on-settle**: Applying a batch of feature
  changes MUST invalidate the provisioned-features cache entry after it
  settles — on success AND on failure, since a failure partway still
  changed part of the list.
- **features-no-client-dedupe**: Applying a batch of feature changes MUST
  pass the add and remove lists through as given — it does not deduplicate
  keys or reject a key present in both; because adds run first, such a key
  is provisioned and then removed.
- **features-mutation-null-id-unguarded**: the feature-provisioning mutations accept an
  ecosystem id that may be absent and MUST proceed without a guard; a mutation fired before the id
  resolves sends its request to a path segment holding a literal absent-marker rather than failing
  fast on the client.

