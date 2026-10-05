
- **Data collected**: Local filesystem paths (the repository's own path,
  its directory, every primary/directory this file is asked to resolve
  and cache), the repository's id, and whatever a pane or the project
  window itself chooses to store under pane state and project settings —
  per the source's own documentation, the lists panes remember through
  this interface "are file paths". No credential, token, or
  network-identity data passes through this file.
- **Storage**: Everything persisted here (tabs, pane state, project
  settings, extra directories) is written to the one database this
  project was constructed with, scoped by the repository's id; see
  `adtoolkit://cookbook/workspace/projects/project-database` and
  `adtoolkit://cookbook/workspace/projects/project-database-layout`
  for that store's own durability guarantees. The cache directory names,
  but does not itself populate, a filesystem location beside the
  database.
- **Transmission**: This file makes no network call and sends nothing
  off the local machine; the git-status-provider lookup hands out a
  collaborator that may run local git subprocesses, not a network
  client.
- **Retention**: Data persisted through this file survives until
  explicitly overwritten or deleted through the same accessor (writing a
  setting with no value deletes rather than storing an empty value, per
  **setting-nil-deletes-row**) or until the underlying repository row
  itself is deleted, which is outside this file's own methods.

