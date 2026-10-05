
- **Data collected**: None beyond the spacing numbers themselves — window/
  pane layout preferences, not personal or sensitive data — and this file
  only holds them in memory as `value`.
- **Storage**: Not applicable to this control itself — it performs no read
  or write to disk or any other store. Persistence, when the control is
  used via its settings-bound construction path, is owned by a separate
  settings-binding layer outside this recipe's scope (see `pane-spacing`
  for one such settings-backed store).
- **Transmission**: Not applicable — no networking call appears anywhere in
  this file.
- **Retention**: Not applicable within this file — the component retains
  only its own child elements, its `value`, and (when bound) its settings
  binding, for its own lifetime; it persists nothing beyond that itself.

