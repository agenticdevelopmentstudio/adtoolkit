
This extension persists user-chosen filesystem paths and arbitrary
caller-supplied strings to local disk:

- **Data persisted**: a tab record's working directory (an absolute
  filesystem path, may embed the user's home-directory name),
  `project_directories.path` (absolute filesystem paths),
  `pane_state.value` (an arbitrary string set by the caller — file paths,
  selection state, or other UI state), and a tab record's title
  (user-chosen or caller-generated text).
- **Storage**: written to the same local SQLite file the base project
  database opens; this extension applies no encryption of its own, and
  nothing in the project database's setup sets an encryption pragma.
- **Transmission**: none — this file makes no network call anywhere.
- **Retention**: rows persist until explicitly replaced or deleted — a
  whole-arrangement replace on every write-tabs/save-project-directories
  call, a cascade delete when the owning `git_repo` row is deleted
  (**cascade-delete-on-repo-removal**), and an explicit sweep for orphaned
  `pane_state` rows (**save-tabs-pane-state-orphan-sweep**,
  **prune-nested-pane-state-scope**); nothing here expires a row by age.

