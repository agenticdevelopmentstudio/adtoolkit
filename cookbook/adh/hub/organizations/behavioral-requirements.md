
### Types

- **organization-shape**: an organization record MUST carry `id`, `slug`, `name`, `description?:
  string | null`, and `rdid?: string`.
- **organization-rdid-presence**: an organization record's `rdid` MUST be present only on the
  response to a create request; a plain read (resolve) or a rename response MUST omit it.
- **organization-list-row-omits-owner**: an organization's list-row shape MUST carry only `id`,
  `slug`, `name`, `description?` — it MUST NOT carry an owner-kind/owner-id pair. This pair was
  removed because nothing read it: which workspace was asked is already the answer to "why is this
  org in the list."
- **organization-create-input-shape**: a create-organization input MUST carry exactly `slug` and
  `name` — every other organization property is provisioned server-side.
- **organization-provisioned-shape**: a create-organization result MUST carry the created
  `organization`, a `namespace` (`id`, `ownerKind`, `ownerId`, `slug`, `name`, `rdid`), a `teamId`,
  and an `ecosystem` (`id`, `slug`, `rdid`).
- **organization-rename-input-shape**: a rename-organization input MUST make `name`, `slug`, and
  `description` independently optional; a caller MUST supply at least one of the three.
- **organization-restored-shape**: a restore-organization result MUST carry exactly one field,
  `organization`.
- **workspace-member-shape**: a workspace member record MUST carry `userId`, `email?: string |
  null`, `displayName?: string | null`, `isAdmin`, and `addedAt`.
- **workspace-member-nullable-fields**: a workspace member record's `email` and `displayName` MUST
  be `null` (not merely absent) for a member outside the caller's ecosystem, per an RLS-bounded
  read, the same pattern team rosters use.
- **workspace-member-is-admin-definition**: a workspace member record's `isAdmin` MUST represent
  admin of ANY of the organization's teams — the roster's strongest role.
- **workspace-member-added-at-definition**: a workspace member record's `addedAt` MUST represent
  the EARLIEST membership timestamp across the organization's teams.

### Listing and resolution

- **organization-list-workspace-required**: the list operation MUST take a workspace slug as a
  required parameter; no workspace-less listing exists.
- **organization-list-request-shape**: the list operation MUST send `GET
  /api/organization/organizations` with a `workspace=<encoded workspace slug>` query parameter,
  and MUST return the response body unwrapped as an array of list-row shapes.
- **organization-list-semantics-by-workspace-kind**: the set of rows the list operation returns
  MUST depend on the named workspace's kind: a personal workspace's rows MUST be the organizations
  the caller owns plus the organizations the caller belongs to; an organization workspace's rows
  MUST be only the organizations that organization owns.
- **organization-resolve-request-shape**: the resolve operation, given a key, MUST send `GET
  /api/organization/organizations/<encoded key>` and MUST return the parsed body verbatim as an
  organization record.
- **organization-resolve-key-polymorphic**: the resolve operation MUST pass the key through
  unmodified — the key MAY be a UUID, a slug, or a reverse-domain rdid, and the resolve operation
  MUST NOT attempt to detect which before sending the request.
- **organization-resolve-no-404-mapping**: the resolve operation MUST NOT catch or remap a 404
  response; a not-found key MUST propagate as a thrown HTTP error with status 404, unchanged.

### Creation

- **organization-create-request-shape**: the create operation, given an input and a workspace
  slug, MUST send `POST /api/organization/organizations` with a `workspace=<encoded workspace
  slug>` query parameter, a `Content-Type: application/json` header, and the input
  JSON-serialized verbatim as the body (no compaction), and MUST resolve to the parsed
  create-organization result on success.
- **organization-create-workspace-required**: the create operation MUST take a workspace slug as
  a required parameter, naming both the workspace the organization is created FROM and the
  workspace that WILL OWN it.
- **organization-create-conflict-mapping**: a conflict thrown by the create request MUST be
  remapped to `An organization with that slug already exists.`; any other error MUST propagate
  unchanged.

### Rename

- **organization-rename-request-shape**: the rename operation, given an id and an input, MUST send
  `PATCH /api/organization/organizations/<encoded id>` with a `Content-Type: application/json`
  header and the input's set fields JSON-serialized as the body (with unset fields omitted, not
  sent as explicit nulls), and MUST resolve to the parsed organization record on success.
- **organization-rename-conflict-mapping**: a conflict thrown by the rename request MUST be
  remapped to `That organization slug is already taken.`; any other error MUST propagate
  unchanged.

### Archive and restore

- **organization-archive-request-shape**: the archive operation, given an id, MUST send `DELETE
  /api/organization/organizations/<encoded id>` and MUST resolve to nothing, since a 204 response
  has no body to parse.
- **organization-restore-request-shape**: the restore operation, given an id, MUST send `POST
  /api/organization/organizations/<encoded id>/restore`, MUST parse the response as a
  restore-organization result, and MUST resolve to the wrapped `organization` field, never the
  envelope.
- **organization-restore-conflict-status-based**: a 409 response to the restore operation MUST be
  detected by HTTP status, not by matching the error message text, and remapped to `That
  organization's handle has been taken, so it can't be restored.`; any other error MUST propagate
  unchanged.

### Query caching contract

- **organizations-query-key-is-prefix-only**: the organizations cache-key prefix MUST identify the
  "organizations" namespace by itself, and MUST be treated as a PREFIX a caller extends with a
  workspace slug to form one workspace's complete cache key.
- **organizations-query-key-distinct-from-workspaces-key**: the organizations cache-key prefix
  MUST remain distinct from any workspace-membership cache key a caller separately maintains,
  since the two keys cache the answers to two different questions over two different endpoints.

### Workspace member roster

- **roster-request-shape**: the roster list operation, given a workspace slug, MUST send `GET
  /api/workspaces/<encoded slug>/members` and MUST resolve to the parsed body verbatim as a roster
  response envelope (not unwrapped to a bare array, unlike the organizations list operation).
- **roster-distinct-customers**: the resolved roster's members MUST be the distinct customers
  across the organization's org-owned teams; a customer belonging to more than one of the
  organization's teams MUST appear exactly once.
- **roster-not-found-semantics**: the roster list operation MUST propagate a 404 unchanged both
  for a slug naming no organization workspace and for an organization workspace the caller is not
  a member of; it performs no client-side membership check of its own.

### Cross-cutting

- **every-call-url-encodes-identifiers**: every organizations and roster operation MUST
  percent-encode every caller-supplied identifier it places in a URL (workspace slug, key, id,
  roster slug).
- **no-client-side-cache**: the organizations operations and the roster operation MUST NOT
  cache or memoize any response themselves; every call issues exactly one HTTP request.
- **module-holds-no-mutable-state**: the organizations operations and the roster operation MUST NOT
  hold mutable state across calls; the only persistent value besides the URL templates each
  operation builds inline is the read-only organizations cache-key prefix. Unlike the sibling
  Ecosystems/Access clients, no shared base-route constant is extracted for either.

### Security

This is a security-relevant recipe: create, rename, archive, and the roster read are all gated by
organization- and workspace-level authorization roles. It carries no secret of its own — the
bearer credential lives in the shared authenticated request client, which this domain composes
rather than reimplements.

- **auth-delegated-to-shared-client**: every network call in both the organizations and roster
  operations MUST go through the shared authenticated request client, which attaches
  `Authorization: Bearer <token>` from the stored access token; both MUST NOT read, store, or attach
  a token itself.
- **session-refresh-waterfall**: a 401 response to any call MUST trigger exactly one token refresh
  and one retried request, inherited unconditionally from the shared client; a second 401 on the
  retried request MUST propagate as a thrown HTTP error with status 401.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved 401 MUST cause
  the call to throw an HTTP error, carrying the response's HTTP status and, when the body supplies
  one, a machine-readable code.
- **authorization-enforced-server-side**: the organizations operations and the roster
  operation MUST NOT perform any client-side permission check before sending a request: create's
  split (open in a personal workspace, admin-of-the-organization required from an organization
  workspace), rename's split (name/description need org-team-admin, slug needs site-admin),
  archive's allowed roles (organization creator, org-team admin, or site-admin), and the roster's
  membership gate are all enforced entirely by the backend — a violation surfaces as a 403 (or,
  for the roster, a 404) that this client does not distinguish or pre-check.

