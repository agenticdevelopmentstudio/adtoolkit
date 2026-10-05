
- **Data collected**: No user content. The only data held is each open
  window's currently active pane identifier — a value assigned by the pane's
  own view controller when it is created, not derived from anything the user
  types or enters.
- **Storage**: In-memory only, in a small number of private collections that
  live only as long as the app process; nothing in this file writes to disk,
  persistent settings storage, or any database.
- **Transmission**: None. Nothing in this file makes a network call or
  passes its state outside the process.
- **Retention**: A window's active-id entry is removed when its active pane
  departs with no survivor (**departure-clears-active-id-when-no-pane-survives**)
  or when the window closes (**window-close-clears-active-id-silently**).
  Nothing here is persisted across an app relaunch — which pane a window was
  last active in is not restored automatically by this component.

