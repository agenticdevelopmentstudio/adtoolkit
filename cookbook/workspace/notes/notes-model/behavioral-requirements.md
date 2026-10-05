
### Note

- **note-identity**: A note MUST be uniquely identifiable and comparable
  for equality, MUST be safe to pass across concurrent contexts, and its
  id MUST be immutable once created.
- **note-fields**: A note MUST carry exactly `content` (text),
  `createdDate` (immutable), `modifiedDate`, and `isPinned` as its stored
  state; it MUST have no stored `title` field.
- **note-title-derivation**: A note's title MUST be computed on every
  access from its content via the shared markdown title-derivation
  utility, never stored, so it can never go stale against content
  between an edit and the next save.
- **note-excerpt-derivation**: A note's excerpt MUST be computed via the
  shared markdown excerpt-derivation utility, applied to the note's
  content together with its frontmatter, which MUST skip the line the
  title was derived from so a heading used as the title is never repeated
  as the first line of the excerpt underneath it.
- **note-untitled-sentinel**: A note's untitled-title sentinel MUST be the
  same sentinel value the markdown utilities themselves define for
  "untitled," not a second string with the same text, so a comparison
  against it can never disagree with the markdown layer's own sentinel.
- **note-default-sort**: A note's default sort order MUST place pinned
  notes before unpinned notes, and within each group order by
  `modifiedDate` descending.
- **note-factory**: Creating a new note from content MUST produce a note
  with a fresh unique id, `createdDate` and `modifiedDate` both set to the
  current time, and `isPinned` false.

### NoteFolder

- **notefolder-value-semantics**: A note folder MUST be uniquely
  identifiable, comparable for equality, and hashable by value — not by
  object identity — and MUST be safe to pass across concurrent contexts.
  Value-based hashing here is deliberate, not an accidental default: a UI
  element that tracks expansion or selection state by matching folder
  values across reloads needs two equal folders produced by two separate
  reads to hash equally, which a reference/object-identity-based hash
  would not guarantee (see Platform Notes).
- **notefolder-all-notes-sentinel**: An id of the empty string MUST be
  reserved for the synthetic "All Notes" root; the folder-tree-building
  operation MUST never itself produce a node with an empty id, since
  every real category id is a lowercased unique identifier minted at
  category-creation time.
- **notefolder-tree-multi-parent**: The folder-tree-building operation
  MUST build a category reachable from more than one parent once per
  parent, so it appears as an independent value under each parent rather
  than a shared reference.
- **notefolder-tree-direct-counts**: Each built folder's note count MUST
  be the category's own direct count from the supplied counts, never a
  sum over its children; a parent's count MAY therefore be smaller than
  the sum of its children's counts.
- **notefolder-tree-total-independent**: The caller MUST supply the "All
  Notes" total count separately (e.g. from the store's own note-count
  query) rather than deriving it by summing the per-category counts,
  because a note filed under two categories would double-count that sum
  and an uncategorized note would be missed by it entirely.
- **notefolder-tree-cycle-safety**: The folder-tree-building operation
  MUST bound every downward walk with a set of the ids already on the
  current path, so a cycle in the edge data truncates that branch instead
  of recursing forever; when every category lies on a cycle with no true
  root, it MUST fall back to treating every category as a root rather
  than losing the graph entirely.
- **notefolder-tree-orphan-edges**: The folder-tree-building operation
  MUST ignore any edge whose parent or child id is not present in the
  supplied category list.

### NoteStorage & NoteTaxonomyProviding

- **notestorage-contract**: The storage contract MUST declare exactly
  four operations that can fail — fetch all notes, insert a note, update
  a note, and delete a note by id — and MUST itself be safe to call from
  multiple threads, since the manager calls these operations off the
  primary thread; the thread safety of the concrete storage is the
  conformer's own responsibility, stated as a precondition, not enforced
  by the contract itself.
- **notetaxonomyproviding-contract**: A storage implementation MAY
  additionally support a taxonomy-provider extension to expose its
  backing document store for taxonomy (folder) queries; the base storage
  contract itself MUST NOT reference categories, so a storage backend
  with no taxonomy concept can implement the base contract alone and
  simply not support folders.

### MarkdownNoteStorage

- **markdownnotestorage-safe-for-concurrent-use**: The markdown-backed
  conformer MUST be safe to use concurrently; its only stored state is a
  reference to the markdown document store (itself declared safe to
  share across threads, by a manually-verified guarantee) and a fixed
  constant, so this safety property holds as written with no additional
  synchronization.
- **markdownnotestorage-note-mapping**: The markdown-backed conformer
  MUST represent a note as a markdown document carrying the `.note`
  marker, and fetching all notes MUST skip any document whose id does not
  parse as a valid unique identifier rather than crashing on it — a
  document with a non-unique-identifier id is server-authored and outside
  this model's addressing scheme.
- **markdownnotestorage-fetch-sort**: Fetching all notes MUST return its
  notes sorted by the note's default sort order (pinned-first, then
  `modifiedDate` descending).
- **markdownnotestorage-timestamps**: Inserting a note MUST stamp the
  underlying document's current-time and created-time parameters
  separately, from the note's `modifiedDate` and `createdDate`
  respectively, so a note's original creation date is preserved
  distinctly from its last-modified date rather than both collapsing
  onto one write timestamp.
- **markdownnotestorage-frontmatter-ownership**: The markdown-backed
  conformer MUST record, per document, which frontmatter keys it itself
  wrote, and MUST use that recorded fact — never the key's value — to
  decide whether a `pinned` key found in a document's frontmatter
  reflects this app's own pin state or a foreign key a user or another
  tool wrote.
- **markdownnotestorage-pin-claim-rule**: The markdown-backed conformer
  MAY claim (write and own) the `pinned` key only when it is currently
  absent from the document's frontmatter, or when writing the desired
  value would change no bytes of the document's content; it MUST NOT
  claim or rewrite a `pinned` key that already holds a different, foreign
  value or a differently-quoted/differently-styled equivalent value.
- **markdownnotestorage-pin-release-rule**: Whenever updating a note
  finds the note's content differs from what this layer last derived for
  it (the stored content with owned keys stripped), it MUST treat the
  entire frontmatter as released — the user edited the text — clearing
  the ownership record for that document before deciding whether to
  write `pinned` again in the same call.
- **markdownnotestorage-title-never-written**: The markdown-backed
  conformer MUST NOT write a `title` frontmatter key under any
  circumstance; a note's title is always derived from its content, and a
  hand-typed `title:` fence MUST be left untouched, exactly like any
  other foreign frontmatter key.
- **markdownnotestorage-strip-on-read**: The markdown-backed conformer
  MUST strip only the frontmatter keys it owns from the text it exposes
  as a note's content; every other line — including a foreign `pinned:`
  key — MUST remain visible, in its original order, in that content.
- **markdownnotestorage-update-atomicity**: Updating a note MUST perform
  its read, merge, and write as a single transaction, not as separate
  read-then-write calls, so a concurrent writer's in-transaction append to
  the same document (e.g. to an unrelated field) survives an update call
  on that document; this buys atomicity, not ordering — two concurrent
  updates on the same note still resolve last-writer-wins over the whole
  note.
- **markdownnotestorage-update-missing-throws**: Updating a note MUST
  fail when the note's id does not correspond to an existing document.
- **markdownnotestorage-delete**: Deleting a note by id MUST remove the
  corresponding document from the store by delegating to the store's own
  document-delete operation.

### NotesManager

- **notesmanager-confined-to-primary-thread**: The manager MUST be
  confined to the primary UI thread; its published state (the notes list,
  the load-completion flag, the storage failure) MUST be read and
  mutated only there.
- **notesmanager-change-notification**: The manager MUST post a change
  notification (with the manager itself as the subject and no payload)
  after every operation that changes the notes list — a load, a create, a
  content update, a pin toggle, or a delete — so an observer re-reads the
  notes list from the posting manager rather than from a stale payload
  snapshot that could already be out of date by the time it is read.
- **notesmanager-failure-surface**: The manager MUST record a failed
  storage operation as a single failure record carrying the operation and
  the error's description, log it as an error, and post a storage-failure
  notification; a new failure MUST overwrite rather than queue behind a
  previous one, since a failing store fails every subsequent operation
  identically. The manager's failure-reporting entry point MUST apply
  this same recording for a failure the manager did not itself trigger —
  a caller that wrote to the manager's wrapped document store directly.
- **notesmanager-clear-failure**: Clearing the storage failure MUST set it
  to unset; it is the only way the storage failure is cleared, so
  whichever host shows the failure is responsible for calling it.
- **notesmanager-load-failure-keeps-loaded-true**: When fetching all notes
  fails, loading notes MUST still mark the manager as loaded and MUST
  leave the notes list as it was (empty, on first launch) rather than
  leaving the manager perpetually unloaded.
- **notesmanager-create-rollback**: When inserting a note fails, creating
  a note from content MUST record the failure, return nothing, and MUST
  NOT append the note to the notes list — a note that was never durably
  persisted MUST NOT remain visible in the list.
- **notesmanager-content-update-debounced**: Updating a note's content
  MUST update the in-memory note, re-sort the notes list, and post the
  change notification synchronously, then MUST schedule the actual
  storage write through a per-note debounced save (a 1-second debounce,
  keyed by note id) rather than writing to storage immediately.
- **notesmanager-debounce-reread**: A scheduled debounced save MUST
  re-look-up the note by id inside the scheduled work rather than
  capturing a snapshot at schedule time, so a save that runs late, or is
  retried after a failure, persists the note as it stands when the save
  actually executes, not as it stood when the keystroke landed.
- **notesmanager-debounce-retry**: A debounced save whose write fails
  MUST remain pending and be retried with backoff, rather than being
  dropped after a single log line.
- **notesmanager-pin-toggle-immediate**: Toggling a note's pin state MUST
  update the in-memory note, then write it through storage immediately on
  a snapshot of the just-toggled note, bypassing the content-update
  debounce entirely.
- **notesmanager-delete-optimistic**: Deleting a note by id MUST remove
  the note from the notes list before attempting the storage delete, and
  MUST record — but MUST NOT use to reinstate the note — a failure of
  that storage delete.
- **notesmanager-storage-off-primary-thread**: Every storage operation
  the manager issues MUST run off the primary UI thread, through a
  detached unit of work, because the concrete storage's I/O (e.g. the
  markdown-backed conformer's local-database calls) would otherwise block
  every other host confined to that thread and sharing this manager (a
  second notes window, Quick Note) for the duration of the call.
- **notesmanager-storage-issue-order**: The manager MUST serialize its own
  storage calls into one ordered chain, so each next call awaits the
  previous one and they execute in the exact order they were issued,
  never overlapping and never reordered — because updating a note carries
  a whole note snapshot taken on the primary thread, and an out-of-order
  write (a stale content save landing after a newer pin toggle) would
  resurrect superseded content. This ordering covers only calls issued by
  this one manager instance; a second, independent writer against the
  same storage contract is outside its scope.
- **notesmanager-markdown-store-accessor**: The manager's markdown-store
  accessor MUST return the wrapped document store only when the storage
  implementation also supports the taxonomy-provider extension, and MUST
  return nothing otherwise, so a host whose storage is not
  markdown-store-backed (e.g. a test double) can treat the folders
  feature as simply unavailable.
- **notesmanager-flush-before-termination**: Flushing pending saves MUST
  synchronously drain every pending debounced save and MUST return the
  ids of any note whose flushed write still failed, so a caller invoked
  before app termination can act on what did not reach disk.
- **notesmanager-logging**: The manager MUST log every storage failure as
  an error, including the operation's name and the error's description,
  and MUST log a successful load as informational, including the count of
  notes loaded.

