
- **Data collected**: None by this module; it stores whatever rows its caller writes.
- **Storage**: A plain, unencrypted SQLite database file (plus its companion write-ahead-log and shared-memory files) at the caller's configured path, typically inside a per-app dotfolder in the home directory; an in-memory database is never written to disk.
- **Transmission**: None; the module performs no network I/O.
- **Retention**: Data persists until the caller deletes it or the file; the module deletes nothing.

