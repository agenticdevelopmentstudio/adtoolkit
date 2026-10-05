
- **Data collected**: This pane introduces no new data collection. It
  contributes the pane's chrome state (minimize edge, zoomed flag —
  persisted by the shared pane chrome) and, when `stateOwnerNodeID` is
  set, redirects which layout node that state is attributed to. No
  personal or sensitive data is read or written by this file.
- **Storage**: Local only, via the project's own database, through the
  shared project workspace and pane state store. This file holds no
  storage of its own.
- **Transmission**: None. No network call appears anywhere in this file or
  its immediate collaborators.
- **Retention**: Tied to the owning layout node's lifetime — the pane
  state store documents that a sweep deletes every `pane_state` row whose
  `node_id` is no longer a layout node, so a closed pane's (or its owner's)
  state is deleted with it; this pane does not manage that lifetime
  itself.

