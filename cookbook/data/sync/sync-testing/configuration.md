
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pullOnlyResources` | `Set<String>` | `[]` | `InMemorySyncStore.init` — resources `stage(_:)` refuses with `pullOnlyResource` |
| `pulls` | `[Outcome<SyncPullResponse>]` | `[]` | `ScriptedSyncTransport.init` — initial pull script, consumed FIFO |
| `pushes` | `[Outcome<SyncPushResponse>]` | `[]` | `ScriptedSyncTransport.init` — initial push script, consumed FIFO |

No environment variables, settings keys or injected dependencies are read. The opId generator `SyncID.uuidV7()` is called directly and cannot be injected.

