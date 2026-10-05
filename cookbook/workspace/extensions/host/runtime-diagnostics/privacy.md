
- **Data collected**: Neither piece collects data on its own initiative.
  Recording a hit accepts a caller-supplied `detail` string that becomes
  part of a logged and published row; its own documented constraint states
  it explicitly: "a document URI or a server name is the useful thing,
  never anything drawn from the file's contents." Enforcing that constraint
  is the caller's responsibility — every current call site passes a
  document URI or a token-type name, never document text.
- **Storage**: In-memory only. The ledger's rows are a plain in-memory
  table with no disk, database, or persisted-settings storage of any kind.
- **Transmission**: None. Neither piece makes a network call; the
  live-rows publisher delivers rows only to in-process subscribers.
- **Retention**: A row persists only until the process exits or an explicit
  clear empties the ledger; nothing in either piece writes a row to
  persistent storage, so no data survives a relaunch.

