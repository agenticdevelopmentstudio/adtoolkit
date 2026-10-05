
- **Null and empty input**: The read-file, read-directory, stat, delete,
  and both sides of the rename operation all treat an empty path string the
  same way they treat any other path nothing resolves at: the underlying
  file-system lookup reports it as absent, and the operation throws its
  not-found/not-a-directory-shaped outcome rather than a distinct "empty
  path" error, since no outcome singles that condition out. The write-file
  operation with zero-length contents MUST still create or replace the
  file — an empty file is a valid outcome, not an error — since writing
  bytes places no minimum-length requirement on its argument.
- **Boundary values**: The read-directory operation against a directory
  with zero children MUST answer an empty list, not throw, since listing a
  directory's contents succeeds on an empty directory the same way it does
  on a populated one. A path that is a symbolic-link chain terminating in
  another symbolic link (rather than a file or directory) is not addressed
  by any operation's own documentation; stat still reports the first link's
  own type without walking further, per **stat-does-not-follow-terminal-
  link**, while the read-file/read-directory link-following requirements
  resolve the whole chain because that is what the underlying path-based
  read operations do.
- **Concurrent access**: Per **concurrent-instance-ordering**, two service
  instances, or this component and an external process, racing the same
  path have no ordering, mutual exclusion, or overlap detection between
  them; each instance's serial queue only orders its own calls
  (**calls-serialize-on-the-queue** establishes that narrower guarantee,
  and no requirement here claims more).
- **Error states**: The rename operation's overwrite path
  (**rename-overwrite-sequence**) has a genuine, documented failure window
  — **rename-overwrite-failure-window** — where a successful removal of
  the occupying item followed by a failed retry move permanently loses that
  item's former contents; this component states this plainly rather than
  claiming a rollback it does not perform. Every other operation's failure
  modes are either a clean refusal before anything is written (a not-found
  outcome before a write, an already-exists/directory-not-empty outcome
  before a remove) or a best-effort classification
  (**permission-detection-best-effort**) that falls back to an
  operation-shaped error rather than misreporting the cause.
- **Offline / disconnected state**: Not applicable — every operation acts
  on a local file-system path; none of the three source units reference a
  network call or any remote dependency whose availability could vary.
- **Crash / power-loss recovery**: Not addressed by this component at all
  — the write-file operation writes in place (**write-file-not-atomic**)
  with no journal, temp file, or write barrier of its own, and the rename
  operation's overwrite sequence performs its remove-then-move-again steps
  with no on-disk marker that would let a later call detect and finish an
  interruption between them the way a recovery sweep would. A power loss
  between the removal and the retried move in
  **rename-overwrite-sequence** leaves exactly the state
  **rename-overwrite-failure-window** already documents as a live risk of
  an ordinary in-process failure at that same point — this component treats
  that window as accepted, not recoverable.

