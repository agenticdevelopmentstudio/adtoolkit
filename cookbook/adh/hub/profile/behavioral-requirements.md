
**Social links**

- **social-links-list-request-shape**: the social-links list operation MUST send
  `GET /api/content/social-links`, appending `?workspace=<enc(workspace)>` only when a workspace
  option is given, and MUST return the parsed body as a list of social-link records with no
  transformation.
- **social-links-create-request-shape**: the social-links create operation MUST send
  `POST /api/content/social-links` (with the same optional `?workspace=` suffix) and a body that
  is the supplied create input JSON-serialized verbatim, and MUST return the parsed social-link
  record.
- **social-links-update-request-shape**: the social-links update operation MUST send
  `PUT /api/content/social-links/<enc(id)>` (with the same optional `?workspace=` suffix) and a
  body that is the supplied input JSON-serialized verbatim, and MUST return the parsed
  social-link record.
- **social-links-delete-request-shape**: the social-links delete operation MUST send
  `DELETE /api/content/social-links/<enc(id)>` (with the same optional `?workspace=` suffix) via
  the shared authenticated request client's no-body-parsing call, not its JSON-parsing call, and
  MUST resolve with no value, discarding whatever body the response carries.

**Addresses**

- **addresses-list-request-shape**: the addresses list operation MUST send
  `GET /api/content/addresses`, with the same optional `?workspace=` suffix as the social-links
  list operation, and MUST return the parsed body as a list of address records with no
  transformation.
- **addresses-create-request-shape**: the addresses create operation MUST send
  `POST /api/content/addresses` (with the optional `?workspace=` suffix) and a body that is the
  supplied create input JSON-serialized verbatim, and MUST return the parsed address record.
- **addresses-update-request-shape**: the addresses update operation MUST send
  `PUT /api/content/addresses/<enc(id)>` (with the optional `?workspace=` suffix) and a body that
  is the supplied input JSON-serialized verbatim, and MUST return the parsed address record.
- **addresses-delete-request-shape**: the addresses delete operation MUST send
  `DELETE /api/content/addresses/<enc(id)>` (with the optional `?workspace=` suffix) via the
  shared authenticated request client's no-body-parsing call, not its JSON-parsing call, and MUST
  resolve with no value.

**Workspace scoping**

- **workspace-query-omitted-when-absent**: the shared workspace-query builder MUST return the
  empty string when no workspace option is given or it is falsy, producing a request URL
  byte-identical to the personal (no-workspace) path.
- **workspace-query-percent-encoded**: the shared workspace-query builder MUST return
  `?workspace=<percent-encoded workspace slug>` when a workspace option is given,
  percent-encoding the slug.

**Cache keys**

- **list-key-namespaced-by-owner**: the social-links, addresses, and usage-summary cache-key
  builders MUST each return a key ending `..., "org", <workspaceSlug>` when a workspace slug is
  given and `..., "self"` otherwise, differing at the same array segment so neither branch is a
  prefix of the other.
- **list-key-roots-not-exported**: the un-namespaced root keys behind the social-links,
  addresses, and usage-summary cache-key builders MUST NOT be exported; only their namespaced
  accessor functions are part of the module's public surface.
- **privacy-key-not-namespaced**: the privacy cache key MUST be exported directly as the fixed
  constant `["account", "privacy"]`, unlike the other three root keys, because privacy grants are
  not owner-scoped by workspace (see `privacy-grants-caller-scoped-only`).

**Privacy grants**

- **privacy-grants-list-unwraps-envelope**: the privacy-grants list operation MUST send
  `GET /api/account/privacy` and MUST return the bare `items` array unwrapped from the
  `{ items }` response envelope.
- **privacy-grants-caller-scoped-only**: the privacy-grants list and set operations MUST NOT
  accept or forward a `workspace` parameter; both operate only on the calling principal's own
  privacy grants.
- **privacy-grant-set-request-shape**: the privacy-grant set operation MUST send
  `PUT /api/account/privacy` with body `{ targetTable, targetId, audienceMask }`, where
  `audienceMask` is looked up from the requested privacy level via the fixed map
  `{"only-me": 0, public: 1, hub: 2}`, and MUST return the parsed privacy-grant record.
- **privacy-level-resolution-default**: resolving a privacy level MUST return `"only-me"` when no
  grant in the supplied array matches the given `(targetTable, targetId)` pair.
- **privacy-level-resolution-match**: resolving a privacy level MUST use the first grant in array
  order whose `targetTable` and `targetId` both match, ignoring any subsequent duplicate entries.
- **privacy-level-resolution-public-precedence**: resolving a privacy level MUST return
  `"public"` whenever the matched grant's `audienceMask` has bit 0 set (`audienceMask & 1`),
  regardless of whether bit 1 is also set.
- **privacy-level-resolution-hub**: resolving a privacy level MUST return `"hub"` when the matched
  grant's `audienceMask` has bit 1 set (`audienceMask & 2`) and bit 0 is not set.
- **privacy-level-resolution-unmatched-bits**: resolving a privacy level MUST return `"only-me"`
  when a grant matches but its `audienceMask` has neither bit 0 nor bit 1 set.

**Usage**

- **usage-summary-request-shape**: the usage-summary operation MUST send
  `GET /api/usage/summary`, appending `?workspace=<enc(workspace)>` only when a workspace option
  is given, and MUST return the bare `rows` array unwrapped from the `{ rows }` response envelope.
- **usage-summary-subject-list-server-derived**: the usage-summary operation MUST NOT send any
  parameter naming which principals' usage to return beyond `workspace` itself; the subject list
  is derived entirely on the backend.

**Wire shapes**

- **owner-scoped-row-shape**: a social-link record and an address record MUST both carry every
  field of the shared owner-scoped-row shape (`id`, `customerId`, `deletedAt`, `ecosystemId`,
  `ownerKind`, `ownerId`, `createdAt`, `updatedAt`, `syncVersion`, `syncStampedAt`, `syncTxid`) in
  addition to their own fields.
- **write-shapes-exclude-server-managed-fields**: a social-link create/update input and an
  address create/update input MUST include only the caller-writable fields
  (`platform`/`url`/`handle`/`sortOrder?` for the social-link input;
  `label`/`line1`/`line2`/`city`/`region`/`postalCode`/`country` for the address input) and MUST
  NOT include `id`, `customerId`, `ownerKind`, `ownerId`, the timestamps, or the sync fields,
  which the server manages.
- **social-link-sort-order-is-render-order**: a social-link record's `sortOrder` field MUST be the
  field the list route sorts by for the order the public user card renders these in; this module
  performs no client-side sort of its own.
- **privacy-target-table-widened**: a privacy target-table value MUST be a plain string, not a
  closed set of known target tables, so this client cannot refuse a target table the backend
  later adds.
- **usage-limits-enforced-flag**: a usage-limits record's `enforced` flag MUST reflect the global
  kill switch already ANDed into the per-key enforcement decision; when `false`, the quota fields
  are recorded against but never refused (observe-then-enforce).
- **usage-row-kind-application-admin-only**: a usage row with `kind: "application"` MUST only
  appear in the platform-admin ecosystem view — an application belongs to its ecosystem and to no
  workspace, so neither the personal nor the workspace-scoped view can produce one.

**Cross-cutting**

- **every-write-call-serializes-verbatim**: the social-links create/update, addresses
  create/update, and privacy-grant set operations MUST JSON-serialize their body argument with no
  field renaming, omission, or added field beyond what that argument already carries.
- **module-holds-no-mutable-state**: this domain's operations MUST NOT cache, memoize, or retain
  any response across calls; every network operation issues exactly one HTTP request per call,
  and privacy-level resolution, workspace-query building, and the cache-key builders perform a
  pure computation with no I/O.
- **no-runtime-response-validation**: the social-links list, addresses list, privacy-grants list,
  and usage-summary operations MUST return whatever the shared authenticated request client's
  typed result produces, applying no runtime shape check of their own to the response body —
  unlike this cookbook's sibling Access recipe's list-features operation.

### Security

This module carries address rows (physical mailing addresses), the privacy audience settings that
decide who may see a principal's social links and addresses, and metered usage/cost figures (a
usage row's `costMicros` field) — all principal-identifying or financially sensitive data — but it
authenticates and authorizes none of it itself.

- **auth-delegated-to-shared-client**: every network call in this domain MUST go through the
  shared authenticated request client's JSON-parsing or no-body-parsing call (backed by the
  platform's shared auth client), which attaches the bearer credential; this module MUST NOT
  read, store, or attach a token itself.
- **no-client-side-storage-of-sensitive-fields**: this domain MUST NOT persist any address,
  social link, privacy grant, or usage row to any client-side store; every value is held only for
  the duration of the call that produced it.
- **audience-visibility-enforced-server-side**: the privacy-grant set operation MUST NOT perform
  any client-side check of who may currently see a target's content before or after the write;
  this module's role is limited to translating a privacy level to an audience bitmask and sending
  it — enforcement of who is shown what based on the resulting mask happens entirely outside this
  domain.
- **violation-handling-inherited**: a non-2xx response to any call in this domain MUST propagate
  as whatever error the shared authenticated request client throws; this module defines no
  security-violation handling of its own.

