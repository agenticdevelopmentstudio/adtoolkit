
- **Data collected**: `git_repo.path` (an absolute filesystem path, which
  under a typical home directory embeds the user's account name),
  `git_repo.remote` (a git remote URL, stored verbatim exactly as it was
  already read out of the repository's own config by another component),
  and `project_setting.value` (an arbitrary caller-supplied string keyed
  by an arbitrary caller-supplied key, per this component's own design
  rationale "callers own the meaning of their own keys") — this file does
  not know or constrain what a caller stores there.
- **Storage**: Every one of those values is written, unencrypted, to a
  single SQLite file on local disk, with `journal_mode=WAL` meaning
  committed data can additionally live in a `-wal` file alongside the main
  database file until checkpointing or SQLite's own auto-checkpoint
  truncates it. Nothing in this file encrypts the file, redacts a remote
  URL that happens to embed user-info credentials, or restricts the
  file's permissions beyond whatever the underlying directory-creation and
  connection-open calls default to.
- **Transmission**: None — this component makes no network call; every
  method operates on the local file through the SQLite C API.
- **Retention**: Indefinite. A `git_repo` row, its settings, and its
  cascaded layout, tab, and pane rows persist until it is deleted
  (cascading via the foreign keys described in **delete-cascades**) or the
  file itself is removed by something outside this file; nothing in this
  file expires or prunes data on its own.

