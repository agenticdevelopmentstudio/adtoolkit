
- **Data collected**: None beyond what the caller already holds — the bar
  and picker only display server ids/names and active-membership state
  already exposed by the caller-supplied registry and `activeServerIds`
  binding.
- **Storage**: In-memory only, for the view model's lifetime
  (`availableServerIds`, `serverNames`, `activeServerIds`); this file writes
  nothing to disk or any other persistent store. Any persistence of server
  configuration is the registry's responsibility, outside this file.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source; connecting to a configured MCP server is the registry's and the
  client's responsibility, not this file's.
- **Retention**: None beyond the hosting element's and view model's
  lifetime; state is discarded when the view is deallocated.

