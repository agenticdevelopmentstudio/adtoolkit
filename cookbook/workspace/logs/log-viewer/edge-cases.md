
- **Null/empty input**: Whether the controller's last-error value is unset
  or set to a string is the sole discriminator, alongside the connected
  flag, for which of the three status branches (`connected-indicator` /
  `error-indicator` / `connecting-indicator`) applies; an empty string for
  the last-error value is treated as set and so is displayed verbatim as
  the error text — the same branch as any other set value. The
  leading-toolbar-items and extra-trailing-toolbar-items hooks returning an
  empty list (the default) is the normal case, not a special-cased branch:
  the corresponding stack view simply arranges zero subviews.
- **Boundary values**: An extension point overriding `minimumContentSize`
  or `toolbarHeight` with a value of zero or negative is not guarded
  against; the resulting layout constraints are built from that zero or
  negative constant and passed through to the layout system as-is. The
  resulting layout is undefined — this is an unguarded input, not
  documented behavior, and no precondition or assertion rejects it.
- **Concurrent access**: The controller contract and this component are
  both confined to the primary UI thread, and the controller's
  state-change notification is likewise required to fire there, so state
  refreshes are always serialized on the primary thread; there is no
  cross-thread mutation path to define behavior for.
- **Error states**: The controller's last-error string is displayed
  verbatim with no truncation, retry affordance, or dismiss action wired
  anywhere; clicking Pause or Clear while an error is present still calls
  the toggle-pause/clear operation unconditionally — neither call is gated
  on connection or error state.
- **Offline/disconnected state**: The Connecting state (connected flag
  `false`, no last-error value) is this component's sole representation of
  "not yet connected" or "reconnecting"; it renders identically whether the
  transport has never connected or has dropped and is retrying, because the
  controller contract exposes no separate signal for that distinction.
  Actual reconnecting/backoff behavior belongs to the injected controller
  implementation (SSE/HTTP/file-tail), a separate component out of this
  recipe's scope — the component only reads the three properties
  (connected, paused, last-error) it is given.

