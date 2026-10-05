
- Null/empty input (MUST): no entries offered yields an "Add" choice list
  with zero items and a selected index of -1; per
  **ok-button-disabled-when-choices-empty** OK is disabled at load, and per
  **confirm-dismisses-without-onadd-on-invalid-selection** even a forced
  confirm dismisses without reporting a selection, since -1 is never a valid
  index into the offered entries.
- Null/empty input (MUST): the caller-supplied selection callback and the
  offered entries are both required inputs, so there is no path where either
  is missing; the component provides, and needs, no nil-handling path for
  them.
- Boundary values (observed): the "Where" choice always contains exactly the
  four fixed directions, so its selected index is always valid (0 through
  3) through ordinary interaction; the bounds guard in the confirm action
  only ever fails, for "Where", in a hypothetical, non-interactive case.
- Boundary values (observed): the fallback that picks index 0 if "Right"
  were ever absent from the fixed direction list is unreachable in the
  current source, since that list is a fixed four-case list that always
  contains "Right" (see **Design Decisions**).
- Concurrent access: Not applicable — the component confines all reads and
  writes of its offered entries, its two choices, and its two buttons to a
  single thread.
- Error states: Not applicable — the component performs no I/O, no
  throwing call, and no asynchronous work; its only defensive path is the
  index-bounds guard in the confirm action, documented above as a
  boundary-value case rather than an error state.
- Offline/disconnected: Not applicable — the component makes no network
  call anywhere in source.

