
- **Data collected**: None beyond what the project browser already shows
  — a repository's id, name, and local filesystem path — and whether its
  window is currently open.
- **Storage**: The open/closed flag is durable, in the project-settings
  store (local disk only). The live-session bookkeeping (the
  open-controllers table, the open-order list, the project-controllers
  table, the adopted-for-scripting set, the key-observer table, the
  close-observer table) is in-memory only and does not survive a
  relaunch.
- **Transmission**: None; every call this file makes is local (the
  database, the filesystem, and the platform's window/notification
  system).
- **Retention**: The `"window.open"` row for a project lives with that
  project's row and is deleted along with it, per the persisted key's own
  documentation — it is not retained independently of the project it
  describes.
- Every log call in this file explicitly marks the repository name or id
  it logs as public, non-sensitive data; both are already visible to the
  user in the project browser and the window's own title, and no
  credential or token is logged anywhere in this file.

