
- **Data collected**: The engine moves the host's row data (JSON object payloads) between store and transport; it collects nothing of its own beyond the host-supplied `deviceId`.
- **Storage**: The engine persists nothing; all rows, the cursor and the outbox live in the injected store.
- **Transmission**: Outbox ops and `deviceId` leave the device through the injected transport; the engine holds no credentials (the transport does).
- **Retention**: Rows purged by `purgeResources` or cleared by `resetForResync` are removed by the store; rejected and unadoptable ops are quarantined, never dropped, and their retention is the store's.

