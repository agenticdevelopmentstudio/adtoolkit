
**Feature areas**

- **feature-list-scoped-by-workspace**: the list-features operation MUST send a request to
  the features route with a `workspace` query parameter carrying the percent-encoded
  workspace slug.
- **feature-list-unwraps-envelope**: the list-features operation MUST return the bare list of
  feature-area rows unwrapped from the `{ features }` response envelope, not the envelope
  itself.
- **feature-row-shape-validated**: the list-features operation MUST throw a plain error with
  the message `GET /access/features returned a malformed feature list` when the response's
  `features` value is not an array, or when any element is not an object whose `key` and
  `label` are both non-empty strings.
- **feature-order-preserved**: the list-features operation MUST return rows in the order the
  backend sent them; it performs no client-side sort or reorder.
- **fallback-features-not-invoked-automatically**: the fallback feature list MUST NOT be
  substituted automatically by the list-features operation on any failure — it is exported
  for a caller's own catch block, and no path inside the list-features operation reads or
  returns it.
- **fallback-features-fixed-set**: the fallback feature list MUST be exactly the two-entry,
  order-preserving list `[{key:"projects",label:"Projects"},{key:"personas",label:"Personas"}]`.

**Roles**

- **role-list-scoped-by-workspace**: the list-roles operation MUST send a request to the
  roles route scoped by workspace and return the role list unwrapped and unvalidated —
  unlike the list-features operation, no runtime shape check is applied to this response.
- **role-create-request-shape**: the create-role operation MUST send a create request to the
  roles route scoped by workspace, with the role write input (`slug`, `name`, `description?`,
  `defaultFor?`, `grants`) serialized verbatim as the body, and MUST return the created role.
- **role-update-excludes-slug**: the update-role operation's patch input excludes `slug`; a
  role's `slug` MUST NOT be changeable through this operation.
- **role-update-request-shape**: the update-role operation MUST send an update request to a
  specific role's route scoped by workspace, with the patch object serialized verbatim as the
  body, and MUST return the updated role.
- **role-delete-request-shape**: the delete-role operation MUST send a delete request to a
  specific role's route scoped by workspace, and MUST resolve with no value, discarding
  whatever body the response carries.

**Assignments**

- **assignment-list-workspace-wide**: the list-assignments operation called with no scope
  argument MUST send a request to the assignments route scoped only by workspace, with no
  feature/item query parameters, and MUST return the `{ assignments, restricted? }` body
  verbatim.
- **assignment-list-item-scoped**: the list-assignments operation called with a scope
  argument MUST add feature and item identifiers to that same request; unlike the assignment
  write input, the list-assignments operation's scope argument requires feature and item
  together — there is no way to supply only one.
- **assignment-put-upserts-one-per-scope**: the assignment-upsert operation MUST send an
  upsert request to the assignments route scoped by workspace, with the assignment write
  input serialized verbatim as the body, and MUST return the resulting assignment; per the
  source's own comment, this grants or replaces the one role a given subject holds at a
  given scope.
- **assignment-delete-request-shape**: the delete-assignment operation MUST send a delete
  request to a specific assignment's route scoped by workspace, and MUST resolve with no
  value.

**Item restriction**

- **item-restrict-request-shape**: the restrict-item operation MUST send a restrict request
  to the item-restriction route scoped by workspace, with a `{ feature, itemId }` body.
- **item-restore-request-shape**: the restore-item operation MUST send a restore request to
  the item-restoration route scoped by workspace, with a `{ feature, itemId }` body.
- **item-restrict-restore-parse-body**: the restrict-item and restore-item operations both
  parse the response body, despite being declared to resolve with no value; each MUST throw
  the same "unexpected empty response" error that the shared response-parsing helper throws
  whenever the backend answers with an empty (no-content) response, rather than resolving.

**Effective access**

- **effective-request-shape**: the effective-access query MUST send a request to the
  effective-access route with workspace, feature, subject-kind, and subject-id query
  parameters, adding an item identifier only when one is given, and MUST omit that parameter
  from the query entirely (not send it empty) when it is not.
- **effective-response-shape**: the effective-access query MUST return the parsed body
  verbatim as an effective-access row, applying no transformation.
- **restricted-flag-shared-meaning**: the effective-access row's `restricted` flag and the
  optional `restricted` flag on the list-assignments operation's item-scoped response both
  describe the same fact — whether the target item was marked restricted via the
  restrict-item operation — but the list-assignments operation's flag is present only for an
  item-scoped query while the effective-access query's is always present.

**Cross-cutting**

- **every-call-url-encodes-identifiers**: every operation MUST percent-encode the workspace
  identifier and any of the id/feature/item/subject identifiers it places in a URL; the
  subject-kind value on the effective-access query is placed unescaped because it is a
  closed set of literal values, never caller-supplied free text.
- **no-compact-on-write-bodies**: the create-role, update-role, and assignment-upsert
  operations MUST NOT strip unset fields from their input before serializing it; they rely
  on the serialization format's own omission of unset keys, which is sufficient for a plain
  object with optional fields.
- **no-client-side-cache**: the client MUST NOT cache or memoize any response; every call
  issues exactly one request.
- **stateless-module**: the client MUST hold no mutable state across calls; the only
  persistent value is the fallback feature list, a fixed, read-only list.

### Security

This is a security-relevant recipe: it is the client for a role/permission (authorization)
surface. It carries no secret of its own — the bearer credential lives in the shared
authentication client, which this module composes rather than reimplements — and it performs
no client-side authorization check of its own, deferring entirely to the backend.

- **auth-delegated-to-shared-client**: every call MUST go through the shared
  authenticated-request helper, which attaches a bearer credential read from the shared
  token store; this module MUST NOT read, store, or attach a token itself.
- **session-refresh-waterfall**: a `401` response to any call MUST trigger exactly one token
  refresh and one retried request, inherited unconditionally from the shared
  authenticated-fetch layer; a second `401` on the retried request MUST propagate as a
  thrown HTTP error with `status: 401`. This module defines no refresh or retry logic of its
  own.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved `401` MUST
  cause the call to throw an HTTP error, carrying the response's HTTP status and, when the
  body supplies one, a machine-readable `code`.
- **feature-validation-error-is-plain**: the error `feature-row-shape-validated` throws
  carries no `status`, so the shared status-extraction helper returns `undefined` for it,
  distinguishing "the backend answered but the body was malformed" from any HTTP-level
  failure.
- **authorization-enforced-server-side**: the client MUST NOT perform any client-side
  permission check before sending a request. Per the module's own top-of-file comment,
  workspace membership, the admin-only gate on role definition, and the manage-access-verb
  requirement on assignment and restriction writes are enforced entirely by the backend,
  which answers a non-member's read with `404` rather than `403` — so a non-member cannot
  distinguish "this workspace has no such resource" from "you may not see it."
- **no-escalation-is-a-server-guarantee**: the source's own comment states that the server
  enforces no-escalation on assignment and restriction writes; this file contains no code
  that checks or blocks a self-escalating grant — the guarantee is external to it, not
  implemented here.

