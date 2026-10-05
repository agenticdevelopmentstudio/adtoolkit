
- **effective-set-is-intersection**: The client MUST compute its active resource
  set as the server manifest intersected with the host-registered set, on every
  pull response.
- **unregistered-resources-surfaced**: The client MUST ignore manifest resources
  the host did not register and MUST surface them via an observability event.
- **appearance-forces-full-resync**: When a resource enters the effective set
  while the cursor is non-fresh, the client MUST reset its mirror and cursor and
  re-pull from scratch, because rows changed while the resource was outside the
  set are permanently behind the server's single cursor stream.
- **resync-preserves-outbox**: A full resync MUST preserve pending local
  mutations for resources still in the effective set, replaying them with their
  original opIds.
- **disappearance-purges-mirror**: When a resource leaves the effective set, the
  client MUST stop serving it, delete its mirrored rows, and remove its
  registration, without touching the cursor.
- **disappearance-quarantines-outbox**: Pending local mutations for a resource
  that left the effective set MUST move to quarantine — surfaced, never silently
  dropped, never pushed.
- **schema-bump-is-disappear-then-appear**: A registered resource whose manifest
  schemaVersion **changes in either direction** — a rise OR a fall — MUST be
  purged and then treated as an appearance. A downgrade (e.g. a server rollback)
  is as much a schema mismatch as an upgrade: mirror rows written under the old
  version cannot be trusted against the new one, so both directions purge + resync.
- **cursor-is-opaque**: The client MUST treat the cursor as an opaque string —
  never fabricated, parsed, or compared beyond equality — and MUST persist it
  only together with an atomically applied pull batch.
- **tombstones-apply-as-deletes**: A change with op `delete` carries no data and
  MUST be applied as a local soft delete.
- **pull-drains-has-more**: The client MUST continue pulling while the server
  reports more, applying each batch atomically before requesting the next.
- **pull-only-refused-at-stage**: The client MUST refuse to stage a local
  mutation for a route-mode (pull-only) resource at the write path.
- **rejected-is-terminal**: Every push result with status `rejected` (reasons
  include unknown_resource, not_enrolled, route_only, invalid_data,
  constraint_violation) MUST quarantine the op and MUST NOT retry it.
- **conflict-adopts-server-row**: A push result with status `conflict` MUST
  resolve by adopting the server's current row locally (delete wins via its
  deleted_at), preserving the server's sync_version.
- **applied-adopts-new-version**: A push result with status `applied` that
  carries newVersion MUST adopt it as the row's base version immediately.
- **identity-change-purges**: A credential/identity change MUST purge mirrored
  rows, cursor, and the entire outbox before syncing as the new identity.
- **recovery-never-deletes-database**: No recovery or purge path may delete the
  database file; recovery is always row deletion within it.
- **catalog-is-not-authority**: A client-side resource catalog MAY optimize
  behavior (registration lists, pull-only refusal) but the server's manifest and
  push results remain authoritative when they disagree.

