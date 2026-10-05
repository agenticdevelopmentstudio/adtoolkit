
- **Data collected**: Only the row payloads, ops and requests a test supplies.
- **Storage**: In the serialized component's memory only (`resourceStates`, `outbox`, `quarantined`, `conflictLog`, `pullCursors`, `pushedRequests`).
- **Transmission**: None; `ScriptedSyncTransport` makes no network call.
- **Retention**: Until the instance is released; nothing is persisted.

