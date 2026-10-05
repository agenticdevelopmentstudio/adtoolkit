
**Mappers**

- **site-group-view-shape**: the group mapper MUST map a group row verbatim to a group view carrying
  `id`, `slug`, `name`, `retentionDays`, `createdAt`, and `updatedAt`, with no field renamed.
- **site-view-renames-group-id**: the site mapper MUST copy a site row's `siteGroupId` field into the
  site view's `groupId`; every other field (`id`, `slug`, `name`, `createdAt`, `updatedAt`) MUST be
  copied unchanged.
- **endpoint-view-shape**: the endpoint mapper MUST map an endpoint row verbatim to an endpoint view
  carrying `id`, `siteId`, `url`, `kind`, `expectedStatus`, `checkIntervalSeconds`, `isActive`,
  `createdAt`, and `updatedAt`, with no field renamed.

**Groups**

- **group-list-request**: the list-groups operation MUST send `GET /api/monitoring/site-groups` with
  the query string the shared workspace-query builder appends (empty when the `workspace` option is
  absent).
- **group-list-sorted-by-name**: the list-groups operation MUST return the mapped group views sorted by
  `name` via a locale-aware comparison, without mutating the array the request returned.
- **group-create-request**: the create-group operation MUST send `POST /api/monitoring/site-groups`
  (plus the workspace query) with a body built by the body-compaction helper from `{ name, slug,
  retentionDays }`, dropping `retentionDays` from the JSON payload when the caller omits it, and MUST
  return the mapped group view.
- **group-update-request**: the update-group operation MUST send `PUT
  /api/monitoring/site-groups/<encoded id>` (plus the workspace query) with a compacted patch of `{
  name, slug, retentionDays }`, and MUST return the mapped group view.
- **group-delete-request**: the delete-group operation MUST send `DELETE
  /api/monitoring/site-groups/<encoded id>` (plus the workspace query), discarding any response body,
  and MUST resolve with no value.
- **group-delete-cascades**: deleting a group MUST cascade at the database level (`FK ON DELETE
  CASCADE`) to remove every site in that group and every endpoint of those sites; this client issues
  one `DELETE` request and performs no separate cleanup call of its own.

**Sites**

- **site-belongs-to-exactly-one-group**: a site view MUST carry exactly one `groupId` as a required
  field — the single group this site belongs to (1:M; required) — and this client models no
  many-to-many group membership.
- **site-list-request**: the list-sites operation MUST send `GET /api/monitoring/sites` (plus the
  workspace query).
- **site-list-sorted-by-name**: the list-sites operation MUST return the mapped site views sorted by
  `name`.
- **site-list-single-request-only**: the list-sites operation MUST NOT issue a second request to the
  site-groups endpoint or perform any client-side intersection against group membership. An earlier
  implementation did both — a second round-trip, plus a silent-hiding bug, since generic-CRUD lists cap
  at 500 rows and a workspace with more than 500 groups could drop sites whose group fell past that cap
  even though the server still monitors them; the current single-request form replaced it.
- **site-create-request**: the create-site operation MUST send `POST /api/monitoring/sites` (plus the
  workspace query) with a body of exactly `{ name, slug, siteGroupId: <the given groupId> }`, renaming
  `groupId` to `siteGroupId`, sent without passing through the body-compaction helper — all three
  fields are required, so none can be absent.
- **site-update-request**: the update-site operation MUST send `PUT /api/monitoring/sites/<encoded
  id>` (plus the workspace query) with a compacted patch of `{ name, slug, siteGroupId: <the given
  groupId> }` built from the optional update fields.
- **site-delete-request**: the delete-site operation MUST send `DELETE /api/monitoring/sites/<encoded
  id>` (plus the workspace query), discarding the body, and MUST resolve with no value.
- **site-delete-cascades**: deleting a site MUST cascade at the database level to remove every endpoint
  that belongs to it.

**Endpoints**

- **endpoint-list-request**: the list-endpoints operation MUST send `GET /api/monitoring/endpoints`
  with a query string built from a `siteId` parameter, appending `workspace=<value>` only when the
  `workspace` option is given — this is the one operation that builds its query string separately from
  the shared workspace-query builder every other operation here uses.
- **endpoint-list-double-filtered**: the list-endpoints operation MUST re-filter the mapped rows
  client-side to `e.siteId === siteId`, in addition to the server-side `siteId` equality filter the
  query string already applies. This client filter is retained as defense-in-depth and is redundant
  once the server has already scoped the response.
- **endpoint-list-sorted-by-url**: the list-endpoints operation MUST return the filtered rows sorted by
  `url`.
- **endpoint-create-request**: the create-endpoint operation MUST send `POST
  /api/monitoring/endpoints` (plus the workspace query) with a compacted body of `{ siteId, url, kind,
  expectedStatus, checkIntervalSeconds, isActive }`, where `siteId` comes from the operation's own
  `siteId` parameter, not from the caller-supplied body.
- **endpoint-update-request**: the update-endpoint operation MUST send `PUT
  /api/monitoring/endpoints/<encoded id>` (plus the workspace query) with a compacted patch of `{ url,
  kind, expectedStatus, checkIntervalSeconds, isActive }`; `siteId` MUST NOT appear in this patch, so
  this operation cannot reparent an endpoint to a different site.
- **endpoint-delete-request**: the delete-endpoint operation MUST send `DELETE
  /api/monitoring/endpoints/<encoded id>` (plus the workspace query), discarding the body, and MUST
  resolve with no value.
- **endpoint-kind-passthrough**: the create- and update-endpoint operations MUST send the
  caller's `kind` value to the backend as given; the body's `kind` field is typed as an
  unconstrained string and neither operation narrows it against the fixed set of valid endpoint
  kinds (`http`, `tcp`, `icmp`), so a caller can submit an unknown kind such as `ssh` with no
  client-side signal.

**Cross-cutting**

- **every-write-url-encodes-identifiers**: every group, site, and endpoint `id` interpolated into a URL
  path segment MUST be percent-encoded; every `workspace` value MUST likewise be percent-encoded, by
  the shared workspace-query builder in every operation except the list-endpoints operation, which
  percent-encodes it through its own query-string construction instead.
- **optional-fields-omitted-not-nulled**: the body-compaction helper MUST drop only absent-valued keys
  from a write body before it is serialized, preserving any explicit `null` a caller supplies — `null`
  is preserved, as an explicit "clear this column" — though no create/update body field in this module
  accepts `null` itself, so this only matters if a caller bypasses the declared shapes.
- **no-client-side-cache**: the twelve operations MUST NOT cache or memoize a response; every call
  issues exactly one HTTP request (aside from the inherited `401` refresh-and-retry described below).
- **module-holds-no-mutable-state**: the only persistent values this logic holds are the three
  fixed path-string constants and the fixed set of valid endpoint kinds, all read-only; no shared
  mutable state exists for concurrent calls to race on.

### Security

Monitored-sites configuration is not credential data, but every operation is owner/workspace-scoped, so
this recipe carries a dedicated security subsection per the cookbook's cross-cutting authorization
guidance.

- **owner-scoping-server-side**: every operation MUST be owner-scoped server-side: groups by the
  caller's user id; sites and endpoints inherit the user id and owner from their parent at
  create/reparent time.
- **workspace-param-repins-owner**: the optional `workspace` parameter, when supplied, MUST be sent as
  `?workspace=<slug>` on every operation, which pins the operation to the workspace's owning principal
  instead of the caller's own scope; list operations under a workspace MUST return only that
  principal's rows, and item update/delete under a workspace MUST resolve an org-owned row another
  member created.
- **auth-delegated-to-shared-client**: every network call in this module MUST go through the shared
  authenticated request client; this module MUST NOT read, store, or attach a bearer token itself.
- **session-refresh-waterfall**: a `401` response to any call in this module MUST trigger exactly one
  token refresh and one retried request, inherited unconditionally from that shared client; a second
  `401` on the retried request MUST propagate as a thrown typed HTTP error with `status: 401`. This
  module defines no refresh or retry logic of its own.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved `401` MUST cause the
  call to throw a typed HTTP error, carrying the response's HTTP status and, when the body supplies
  one, a machine-readable `code`.
- **no-conflict-friendly-mapping**: no operation in this module calls the shared conflict-friendly-error
  helper to translate a `409` "already exists" backend error into an entity-named friendly message; a
  duplicate group/site/endpoint slug MUST propagate as the raw error message the backend supplied.

