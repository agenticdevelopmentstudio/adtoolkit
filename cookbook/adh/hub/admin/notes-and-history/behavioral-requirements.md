
- **renders-notes-section**: The component MUST render an "Admin notes"
  section.
- **renders-history-section**: The component MUST render a "History" section.
- **sections-load-independently**: The component MUST evaluate the notes
  section's loading state from `notesLoading` and the history section's
  loading state from `historyLoading` independently, so a slow history fetch
  MUST NOT withhold already-loaded notes, and a slow notes fetch MUST NOT
  withhold already-loaded history.
- **notes-loading-indicator**: WHEN `notesLoading` is `true`, the component
  MUST render "Loading…" in place of the notes list or empty message.
- **history-loading-indicator**: WHEN `historyLoading` is `true`, the
  component MUST render "Loading…" in place of the history list or empty
  message.
- **notes-empty-message**: WHEN `notesLoading` is not `true` and `notes` is
  empty, the component MUST render "No admin notes." instead of a list.
- **history-empty-message**: WHEN `historyLoading` is not `true` and
  `history` is empty, the component MUST render "No history." instead of a
  list.
- **notes-list-rendering**: WHEN `notesLoading` is not `true` and `notes` is
  non-empty, the component MUST render one list item per entry in `notes`.
  Each item MUST display that note's `content` on its own line, followed by
  a line reading `author · modifiedDate` — the note's `author` and
  `modifiedDate` joined by a middle dot (`·`) with one space on each side.
- **history-list-rendering**: WHEN `historyLoading` is not `true` and
  `history` is non-empty, the component MUST render one list item per entry
  in `history`. Each item MUST read `timestamp — actor action` — the
  entry's `timestamp` set off by an em dash (`—`) with one space on each
  side, followed by `actor` and `action` separated by a single space.
- **preserves-source-order**: The component MUST render notes and history
  list items in the same order as the `notes`/`history` arrays supplied by
  the caller; it MUST NOT sort or otherwise reorder them.
- **no-internal-data-fetching**: The component MUST NOT issue a network
  request or otherwise fetch `notes`/`history` itself; it MUST render
  exclusively from the `notes`, `history`, `notesLoading`, and
  `historyLoading` parameters supplied by the caller.
- **loading-props-default-to-false**: WHEN `notesLoading` or
  `historyLoading` is omitted, the component MUST treat the omitted flag as
  `false` — i.e. it MUST evaluate the corresponding empty/populated branch
  rather than the loading branch.

