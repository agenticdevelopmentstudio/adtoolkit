
**Personal API tokens**

- **token-list-request-shape**: Listing tokens MUST send `GET /api/auth/tokens` and MUST return the
  parsed token list verbatim, applying no transformation.
- **token-scopes-unwraps-envelope**: Fetching the scope catalogue MUST send `GET
  /api/auth/tokens/scopes` and MUST return the bare `prefixes` array unwrapped from the `{ prefixes }`
  response envelope, not the envelope itself.
- **token-mint-request-shape**: Minting a token MUST send `POST /api/auth/tokens` with the caller's
  mint body (`name`, `expiresAt?`, `scope?`) JSON-serialized verbatim as the body, with no compaction or
  other transformation applied first, and MUST return the parsed created-token response.
- **token-revoke-request-shape**: Revoking a token MUST send `DELETE /api/auth/tokens/{id}`, with `id`
  percent-encoded, and MUST resolve with no value, discarding whatever body the response carries.
- **token-created-secret-returned-once**: A minted token's secret field is documented as "the raw token
  value — shown exactly once"; minting MUST return that field to the caller unmodified as part of the
  resolved created-token response, and MUST NOT retain, log, or resend it itself.
- **token-metadata-never-carries-secret**: Every other tokens operation (listing, fetching scopes,
  revoking) MUST operate only on the non-secret token record, whose fields are `id`, `name`, `prefix`
  (documented as "non-secret leading chars, for display"), `createdAt`, `expiresAt`, `lastUsedAt`, and
  an optional `scope`; these three operations MUST NOT ever receive or return the raw secret.

**Bucket access lists**

- **access-list-all-groups-cross-bucket**: Listing all access groups MUST send `GET
  /api/bucket/access-groups`, unscoped to any single bucket, and MUST return the group array unwrapped
  from the `{ accessGroups }` envelope; per the source's own documentation, this is the one cross-bucket
  call for the Access pane, in place of a per-bucket listing fan-out, and the caller — not this
  component — MUST join bucket names locally and filter to the ecosystem it is displaying.
- **access-group-detail-request-shape**: Fetching a group's detail MUST send `GET
  /api/bucket/access-groups/{groupId}` (percent-encoded) and MUST return the parsed group detail
  verbatim, including its nested `members` and `grants` arrays.
- **access-group-create-scoped-to-bucket**: Creating a group MUST send `POST
  /api/bucket/buckets/{bucketId}/access-groups` (percent-encoded) with a body of `{ name, description?
  }`, where `name` is the trimmed input name and `description` is included only when the input
  description is truthy.
- **access-group-create-conflict-friendly**: On a caught error whose message matches an "already
  exists" pattern, creating a group MUST rethrow a plain error with the message `An access list named
  "<trimmed name>" already exists.`; any other caught error MUST be rethrown unchanged.
- **access-group-update-request-shape**: Updating a group MUST send `PATCH
  /api/bucket/access-groups/{groupId}` with a body built key-by-key: `name` is included, trimmed, only
  when the caller supplies it, and `description` is included, unmodified, only when the caller supplies
  it.
- **access-group-update-conflict-friendly**: On a caught error matching the same "already exists"
  pattern, updating a group MUST rethrow a plain error with the message `An access list named "<trimmed
  name, or empty string if none was supplied>" already exists.`; any other caught error MUST be
  rethrown unchanged.
- **access-group-delete-request-shape**: Deleting a group MUST send `DELETE
  /api/bucket/access-groups/{groupId}` and MUST resolve with no value; unlike creating/updating a group,
  it applies no error translation of its own, so any error the backend returns — including the conflict
  the seeded "everyone" group's delete always answers with — propagates to the caller unchanged and
  un-translated.
- **access-member-add-request-shape**: Adding a member MUST send `POST
  /api/bucket/access-groups/{groupId}/members` with a body of exactly `{ memberType, memberId }`.
- **access-member-add-conflict-friendly**: On a caught error matching the same "already exists"
  pattern, adding a member MUST rethrow a plain error with the message `That member is already in this
  access list.`; any other caught error MUST be rethrown unchanged.
- **access-member-remove-request-shape**: Removing a member MUST send `DELETE
  /api/bucket/access-groups/{groupId}/members/{memberRowId}` and MUST resolve with no value; per the
  source's own documentation, the member-row id is the membership row's own id, never the principal's
  own id — the backend delete matches on the row id.
- **access-grant-upsert-request-shape**: Upserting a grant MUST send `PUT
  /api/bucket/access-groups/{groupId}/grants` with a body of exactly `{ targetType, targetId, crud }`
  and MUST return the parsed grant; like deleting a group, it applies no error translation, so any
  backend error propagates unchanged.
- **access-grant-delete-request-shape**: Deleting a grant MUST send `DELETE
  /api/bucket/access-groups/{groupId}/grants/{grantId}` and MUST resolve with no value.
- **access-crud-string-passthrough**: Upserting a grant MUST send whatever `crud` string the caller
  supplies (documented as "comma-separated CRUD subset, e.g. `'C,R,U,D'` or `''` (none)") verbatim, with
  no client-side charset, ordering, or length check.
- **access-metadata-not-writable**: The create-group and update-group request bodies MUST NOT
  include a `metadata` field; neither operation can set the `metadata` an access group record carries,
  even though fetching a group or listing all groups MUST return whatever `metadata` the backend
  supplies.

**Cross-cutting**

- **every-bucket-access-call-url-encodes-identifiers**: Every bucket access-list operation MUST
  percent-encode the bucket id, group id, member-row id, and grant id before placing them in a URL.
- **no-compact-on-write-bodies**: Minting, creating a group, updating a group, adding a member,
  and upserting a grant MUST NOT apply a general-purpose field-compaction transform to its body before
  serializing it; each builds its own conditional object shape (or, for minting, serializes the
  caller's object directly), and the standard omission of `undefined`-valued keys during serialization
  is what actually drops absent optionals.
- **no-client-side-cache**: Each client MUST NOT cache or memoize any response; every call issues
  exactly one HTTP request.
- **stateless-module**: Each client MUST NOT hold mutable state across calls; the only persistent values
  are the fixed path constants for the tokens base path, the groups base path, and the buckets base
  path.

### Security

This is a security-relevant recipe: the personal API tokens client issues and revokes the caller's own
bearer-style API credentials, and the bucket access lists client is the client for a resource-level
authorization surface (who may read/write which buckets, bucket types, or rows). Neither client carries
the caller's own *session* credential — that lives in a shared authenticated-request helper, which both
clients compose rather than reimplement.

- **auth-delegated-to-shared-client**: Every token/access-list network call MUST go through the shared
  authenticated-request helpers, which attach a bearer token read from the stored access token; each
  client MUST NOT read, store, or attach a session token itself.
- **session-refresh-waterfall**: A `401` response to any call from either client MUST trigger exactly
  one token refresh and one retried request, inherited unconditionally from the shared request helper;
  a second `401` on the retried request MUST propagate as a thrown error carrying `status: 401`.
  Neither client defines any refresh or retry logic of its own.
- **errors-carry-status-and-code**: Any non-2xx response other than an unresolved `401` MUST cause the
  call to throw an error carrying the response's HTTP status and, when the body supplies one, a
  machine-readable `code`, per the shared request helper's implementation.
- **token-scope-passthrough-unvalidated**: Minting's `scope` parameter (documented as "REST path
  prefixes this token may reach ... optional `:read` suffix, `*` = all") MUST be sent exactly as the
  caller supplies it, with no client-side check that a prefix is well-formed or that `expiresAt` is a
  valid future date; both are backend-validated concerns per this component's own lack of any such
  check.
- **token-can-be-a-grant-principal**: The member-type vocabulary (`"user" | "organization" | "persona"
  | "app" | "token"`) includes `"token"`; adding a member MUST accept a member id that names an API
  token as a bucket access-group member exactly as it would a user or organization, with no distinct
  handling for that case.
- **server-side-grant-and-ceiling-validation**: Per this component's own documentation, the backend
  enforces "grant-target validity and the bucket ≥ type ≥ row ceiling" for every grant an upsert sends;
  this component performs no client-side check of a grant's target hierarchy before sending it.
- **server-side-seeded-group-protection**: Per the same documentation, the seeded `"everyone"` access
  group is undeletable server-side — "delete → 409" — and deleting a group contains no client-side
  check of the group's kind before sending the request; the protection is enforced entirely by the
  backend and surfaced to the caller as an untranslated conflict response, per
  `access-group-delete-request-shape`.

