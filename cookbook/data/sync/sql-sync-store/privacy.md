
- **Data collected**: The store persists whatever row data the host syncs (JSON object payloads), the pull cursor, and conflict reasons; it adds nothing of its own.
- **Storage**: Everything lives unencrypted in the SQLite file at its configured path; the store applies no encryption and relies on the file's location and OS file protection.
- **Transmission**: The store performs no network I/O; outbox ops leave the device only when the caller pushes them.
- **Retention**: Mirror rows stay until a newer pull, `resetForResync`, `purgeResources` or `purgeForIdentityChange` removes them; tombstones stay indefinitely; quarantined ops stay until `purgeForIdentityChange`; `_sync_conflicts` rows (op id, resource, row id, reason) are never deleted, even across an identity change.

