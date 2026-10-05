
- **Data handled**: The `text` argument passed to `send(_:)` and the configured `reply` string are the only content this component touches; both are held only in memory as `ChatMessage.text` values yielded through the event stream `events()` returns. The component defines no credential, token, or other sensitive field.
- **Storage**: The component performs no storage of any kind — no file, database, settings-store, or credential-store write ("No network, no subprocess").
- **Transmission**: None. The component never opens a network connection or spawns a process; every event is produced and consumed entirely in-process.
- **Retention**: None beyond the lifetime of an `events()` subscription. The component holds no transcript array of its own — once a `ChatMessage` is yielded, the instance retains no copy of it (contrast a sibling network- or subprocess-backed `ChatSession` implementation, which does hold loaded/pending message arrays).

