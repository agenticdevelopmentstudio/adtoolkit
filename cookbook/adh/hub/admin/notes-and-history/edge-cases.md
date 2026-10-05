
- Null and empty input: `notes` and `history` are required list parameters,
  so `null`/`undefined` arrays are not valid inputs; the component's only
  check is array length (see notes-empty-message, history-empty-message).
  This handles the empty-array case; it is a MUST.
- Boundary values: No pagination, slicing, or virtualization is applied —
  the component iterates over the full array. The component MUST render
  every element of `notes`/`history` with no cap, however large the array.
- Concurrent access: Not applicable — this is a stateless, pure
  presentational component with no internal mutable state; there is
  nothing for concurrent access to race.
- Error states: Not implemented. The `notesLoading`/`historyLoading`
  parameters imply an underlying async fetch, but the component declares
  no error parameter and no rendering branch for a failed fetch — only
  loading, empty, and populated are handled. A caller whose fetch rejects
  gets no distinct error message (e.g. one separate from "No admin
  notes.") from this component; error handling is fully owned by the
  caller.
- Offline/disconnected: Not applicable — the component performs no
  networking itself (see no-internal-data-fetching); connectivity loss is
  entirely the caller's concern, surfaced (if at all) before `notes`/
  `history`/the loading flags reach this component.
- Duplicate `id` values: Each list item is keyed by its `id` with no
  uniqueness check or de-duplication. Unique `id`s within `notes` and
  within `history` are a caller precondition, not something this
  component validates. WHEN that precondition is violated, the component
  still performs no de-duplication; implementations SHOULD emit a
  dev-mode-only warning when they detect a duplicate `id` (mirroring a
  keyed-list framework's own duplicate-key warning) rather than silently
  rendering whatever a keyed-list collision resolves to on that platform.
- Empty-string field values: An admin note with `content: ""` or a history
  entry with `action: ""` still counts as populated (array length `> 0`)
  and MUST render as a list item with a blank content/action segment,
  since the empty-state check inspects only array length, not field
  values.
- Long text: No truncation or line-clamping is applied. The component MUST
  NOT truncate `content` or `action` text; long strings wrap naturally
  within the container's width.

