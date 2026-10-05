
- **Data collected**: none of this module's own — it receives already-fetched provider status strings and cluster metadata as plain arguments from callers external to this module; it collects nothing itself.
- **Storage**: none. This module holds no state between calls and writes nothing; the SQL fragments it builds are executed by the storage layer, external to this module.
- **Transmission**: none. This module performs no network or database call; every SQL fragment it returns is a string handed back to its caller, which decides whether and how to execute it.
- **Retention**: not applicable — this module holds no data across calls.

