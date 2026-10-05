
One row per Behavioral Requirement.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| R1 | effective-set-is-intersection | host-registered resources `[a.x]`; manifest `[a.x, b.y]` with changes for both | only `a.x`'s changes are applied; `b.y`'s are skipped |
| R2 | unregistered-resources-surfaced | manifest carries `b.y`, which the host did not register | `b.y` is ignored; an `unregisteredManifestResources` event naming `["b.y"]` is emitted |
| R3 | appearance-forces-full-resync | `b.y` enters the effective set on a non-fresh cursor | mirror + cursor reset, full re-pull, a `resourcesEnabled` event naming `["b.y"]` plus `resyncPerformed` |
| R4 | resync-preserves-outbox | a staged op exists when an HTTP 410 forces resync | the op is replayed under its original opId after the re-pull |
| R5 | disappearance-purges-mirror | `b.y` leaves the effective set | its mirror rows are deleted, registration removed, cursor untouched, a `resourcesDisabled` event naming `["b.y"]` |
| R6 | disappearance-quarantines-outbox | a pending op for the departing `b.y` | the op moves to quarantine, never pushed |
| R7 | schema-bump-is-disappear-then-appear | `a.x`'s manifest schema version changes from the registered version — a rise (v1→v2) or a fall (v2→v1) | purged then resynced, a `resourcesSchemaBumped` event naming `["a.x"]`, in both directions |
| R8 | cursor-is-opaque | a pull response whose cursor is an opaque base64 string; applying it fails partway through the batch | the cursor is persisted only with a fully applied batch; it is never parsed |
| R9 | tombstones-apply-as-deletes | a pulled change with op `delete` and no data | the row is soft-deleted locally (drops out of live rows) |
| R10 | pull-drains-has-more | two pages, the first reporting `hasMore = true` | both pages are pulled and applied atomically, cursor advanced per batch |
| R11 | pull-only-refused-at-stage | staging a mutation for a resource in the pull-only set | raises a pull-only-resource refusal error; no outbox op is created |
| R12 | rejected-is-terminal | a push result with status `rejected` | the op is quarantined, absent from the next cycle's push |
| R13 | conflict-adopts-server-row | a push result with status `conflict` and a `current` row carrying the server's sync_version | the server row is adopted locally, its sync_version preserved, bookkeeping columns stripped; when `current.deleted_at` is set, it is adopted as a local delete (mirror row tombstoned) |
| R14 | applied-adopts-new-version | a push result with status `applied` and a `newVersion` | the mirror row's base version is updated before the outbox row is cleared |
| R15 | identity-change-purges | an identity change with mirror rows, cursor, and pending/inflight/quarantined ops present | mirror + cursor + the entire outbox are cleared; registrations are kept |
| R16 | recovery-never-deletes-database | a resync and an identity-change purge on a live on-disk store | only rows are deleted; the store keeps serving afterward (the underlying file survives) |
| R17 | catalog-is-not-authority | the catalog lists a resource the manifest omits (or vice versa) | the manifest gates what actually syncs; the catalog only shapes registration/refusal |

