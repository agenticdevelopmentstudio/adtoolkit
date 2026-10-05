
- **Data collected**: File and directory paths, names, extensions, sizes,
  and modification dates read from the local file system under `rootURL`,
  plus whatever `gitStatus` an external caller assigns
  (`node-git-status-external`). Nothing is collected beyond what already
  exists on the user's own disk.
- **Storage**: This model persists nothing itself; the tree is held only in
  memory for the lifetime of the coordinator and its nodes. The
  configuration value's `customMappingsDefaultsKey` names a storage key,
  but reading or writing that key is owned by a different component (the
  custom file-type mapping table), not this model.
- **Transmission**: None. This model makes no network call.
- **Retention**: In-memory only, for as long as the coordinator/node objects
  live; nothing is written to disk by this model.
- **Log visibility**: The watcher logs its root path with an explicit
  visibility override that keeps it un-redacted, rather than the platform
  logger's default redaction for interpolated values — a deliberate choice
  to keep the watched root's path visible in log output rather than
  redacted (see Design Decisions; see Platform Notes for the exact
  mechanism used on Apple platforms).

