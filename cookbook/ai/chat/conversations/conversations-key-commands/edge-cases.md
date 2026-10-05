
- **Null/empty input**: A resolver that returns no controller is the normal
  case before a window exists (per `absent-window-passes-key-on`).
- **Boundary values**: Moving the selection past either end is the window's
  rule, not this component's; it forwards -1 and +1 only.
- **Concurrent access**: Not applicable: commands run on the UI thread from
  the registry's key monitor.
- **Error states (dependency/network failure)**: Not applicable: no I/O.
- **Offline/disconnected state**: Not applicable.
- **Window closed and reopened** (MUST): because the controller is resolved
  at run time (per `resolve-at-run-time`), commands act on whichever window
  is up when the key is pressed, with no re-installation.
- **Typing in a text field** (MUST): a keystroke the window does not own is
  passed on (per `window-decides-ownership`), so Command-Up in a text field
  keeps its text-editing meaning.

