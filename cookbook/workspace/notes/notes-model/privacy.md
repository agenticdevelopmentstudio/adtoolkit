
- **Data collected**: A note's markdown content (arbitrary user-authored
  text, including any frontmatter the user hand-types into it) plus
  per-note metadata: a unique id, `createdDate`, `modifiedDate`, and
  `isPinned`.
- **Storage**: Persisted locally by whatever storage implementation the
  host injects. The markdown-backed conformer persists a note as a row in
  a local document store (a local database), keyed by
  the note's id lowercased to a string; none of the six sources given
  here adds encryption, secure-credential storage, or any protection
  beyond what that document store itself already applies.
- **Transmission**: None of these six sources calls out to a network
  directly. The markdown-backed conformer's insert operation does enqueue
  a create operation onto the document store's own remote outbox, so a
  note's content and metadata eventually leave the device through that
  separate, already-documented sync path, on a schedule this layer does
  not control.
- **Retention**: A note's content and metadata persist indefinitely until
  deleting it by id removes the row. Flushing pending saves shortens the
  window in which an edit exists only in memory and not yet on disk, but
  it is the caller's responsibility to invoke it (e.g. before
  termination); nothing in these six sources calls it automatically.

