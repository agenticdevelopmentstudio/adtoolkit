
- Null/empty input (MUST): `registry` and `activeServerIds` are both
  required, non-optional parameters, so there is no absent/nil case for
  either. An empty `activeServerIds` value at construction (`{}`) is handled
  identically to any other set — no special-case branch exists for it. An
  empty registry (no clients) drives `computes-no-servers-label` and the
  picker's empty-state message.
- Boundary values (MUST): A registry with exactly one client is handled by
  the same sort/label logic as any other count (`"MCP: 1 of 1"` when that
  one server is active). No maximum server count is enforced anywhere in
  source.
- Concurrent access: Not applicable — both the bar and its view model
  confine every read and write of `availableServerIds`, `serverNames`, and
  `activeServerIds` to a single execution context (see Platform Notes for
  the mechanism); source provides no path for two threads to mutate this
  component's state simultaneously.
- Error states (MUST): the registry's client-list subscription has no
  failure case — its updates never complete with an error — so no
  error-handling branch exists or is needed in this file. No other
  operation in this file (sorting, dictionary construction, set membership)
  can throw.
- Offline/disconnected: Not applicable — this file never opens a network
  connection itself; it only reads the registry's already-resolved client
  list and each client's cached `name`. Whether a given server's underlying
  connection is up, down, or reconnecting is the registry's and the
  client's concern, entirely outside this file, and is not reflected in the
  bar's appearance.
- Stale active ids outlive their server (MUST): `activeServerIds` is only
  intersected with `Set(availableServerIds)` when computing the button's
  displayed count (`computes-count-active-label`); the underlying
  `activeServerIds` set — and the external binding it is written back to —
  keeps any id that the registry has since stopped reporting. If that same
  id's server later reappears in the registry's client list, it is
  immediately reported active again with no re-confirmation step, since
  `toggle(_:)`/`propagates-toggle-to-binding` is the only path that ever
  removes an id from the set (see the "Stale active ids" Design Decision).
- Picker opened with no available servers (MUST): Opening the popover while
  `availableServerIds == []` shows only the empty-state message; the
  `showingPicker` toggle and popover presentation are unaffected by whether
  any servers exist.
- Row toggle setter is not idempotent (MUST): Each row's toggle binding
  reads `viewModel.isActive(id)` and, on any set, ignores the new boolean
  value entirely and unconditionally calls `toggle(id)`, per
  **row-toggle-calls-view-model-toggle**. Setting a row to the value it
  already holds still flips membership, rather than leaving it unchanged.
  The platform's own toggle control only invokes a boolean binding's setter
  when the user's interaction actually changes the displayed value, so this
  does not manifest through normal use, but nothing in the setter itself
  guards against being invoked with a value equal to the current state.

