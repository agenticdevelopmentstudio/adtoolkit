
- An empty-content note (created from an empty string) derives the
  untitled-title sentinel, never an empty string title.
- Writing `pinned` when the document's frontmatter already reads
  byte-identical to the value about to be written claims the key without
  mutating a single byte of content.
- A quoted foreign value the app would otherwise rewrite as an unquoted
  boolean — `pinned: "true"` — is left completely alone and never
  claimed, because rewriting it would change bytes that belong to the
  user.
- A frontmatter `title` written as a flow sequence (`title: [a, b]`), an
  empty string (`title: ""`), or a whitespace-only string
  (`title: "   "`) all fall through to the derived body-line title,
  exactly as the shared markdown title-derivation utility does for every
  other document authored the same way.
- A foreign frontmatter key unrelated to `pinned` (e.g. `author: mike`)
  survives a read and an unrelated no-op re-save byte-for-byte.
- Building the folder tree with no edges at all treats every category as
  an unparented root.
- Deleting a note by an id with no corresponding document does not fail:
  the store's delete operation treats a missing id as success by design
  (the document store's delete operation is idempotent), so calling delete twice for the same
  note is safe.
- Toggling a pin while a debounced content save for the same note is
  still pending does not wait for it: toggling the pin writes through
  immediately against whatever content is already in memory, ahead of
  the debounced write.
- Updating a note's single-transaction read-merge-write buys atomicity
  against a concurrent writer, not ordering between two update calls on
  the same note — the second one to commit always wins over the whole
  note, matching this system's own head-has-no-concurrency-token model.

