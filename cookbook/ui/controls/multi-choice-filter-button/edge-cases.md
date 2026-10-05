
- Null/empty input: `label` (a string) and `choices` (a list of `Choice`)
  are required, non-optional constructor parameters; neither can be
  omitted or left absent. The component therefore provides, and needs, no
  nil-handling path.
- Empty `choices` array: menu construction still produces item 0, "Any",
  and the separator, but no choice items follow. `selection` can never
  become non-empty (there is nothing to toggle), so the title is
  permanently `"<label>: Any"`. The component does not crash or
  special-case this; it falls straight out of the existing
  menu-building and title-formatting logic.
- Duplicate ids within `choices`: the source enforces no uniqueness on
  `Choice.id`. If two entries share an id, both of their menu items match
  the same membership test in the checkmark-resync operation and are
  therefore always kept in the same checked state as each other, while
  `selection` (a set of strings) holds that id only once regardless of how
  many menu entries reference it. This is the source's actual, as-written
  behavior — a duplicate id is not rejected or deduplicated by this
  component itself (see Design Decisions). Callers MUST supply unique ids
  across `choices`; behavior is undefined if two choices share an id.
- Boundary values: the selection-count boundaries are 0, 1–2, and 3+,
  exactly the three branches in **formats-title-none-selected**,
  **formats-title-few-selected**, and **formats-title-many-selected**. MUST:
  the transition from 2 selected ("`a`, `b`") to 3 selected ("3 selected")
  happens at exactly `selection.count == 3`, with no intermediate form.
- Concurrent access: Not applicable — the component is confined to a
  single thread of execution for its entire lifetime, so all construction,
  menu-item actions, and the selection-setting operation are serialized to
  that thread. See Platform Notes for how that
  confinement is enforced.
- Error states: Not applicable — every operation in this file (menu
  building, toggling, title formatting, theming) is synchronous; no
  error-throwing or failure-producing call appears anywhere in source.
- Offline/disconnected: Not applicable — the component performs no
  networking; it only manages an in-process menu and selection set.
- Selecting "Any" while `selection` is already empty: assigning the empty
  set to `selection` when it is already empty leaves it unchanged in
  value, so neither the title-refresh operation nor `onChange` runs. MUST:
  the checkmark-resync operation still runs immediately after, so every
  choice item's checkmark is still resynchronized on this call even though
  nothing visibly changes (see **reflects-checkmarks**).
- The selection-setting operation called with a set that, after discarding
  unknown ids, equals the current `selection`'s value: the same no-op
  suppression applies to the title-refresh operation and `onChange`, but
  the selection-setting operation still runs the checkmark-resync
  operation unconditionally on every call, so checkmarks are still
  resynchronized. MUST: callers relying on `onChange` to detect a call to
  the selection-setting operation MUST NOT assume it fires when the
  resulting set is unchanged.

