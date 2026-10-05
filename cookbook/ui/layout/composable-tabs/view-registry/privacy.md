
- **Data collected**: None. The registry holds only in-process configuration
  (descriptors and factory closures) supplied by the app itself, and the
  placeholder displays only a pane number computed by its caller — no user
  content or identifier.
- **Storage**: In-memory only, in the registry's own private entry map, for
  the life of the registry instance; nothing in this file writes to disk,
  a persistent key-value store, or a database.
- **Transmission**: None. Nothing in this file makes a network call or sends
  its state outside the process.
- **Retention**: Entries live only as long as the registry instance that
  holds them (per project, per composable-tabs layout); nothing here
  persists across a relaunch.

