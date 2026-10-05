
- **Data collected**: none of this file's own. It receives an already-fetched or already-received `ProviderDeploy` (provider status strings, commit metadata, a source URL) and a resolved `liveHost` string as plain function arguments from callers external to this file; it collects nothing itself.
- **Storage**: none. This file holds no state between calls and writes nothing to disk, memory cache, or database; persistence of the data it shapes is owned by the storage layer and `routes/reads.ts`, both external to this file.
- **Transmission**: none performed by this file itself. `providerDeployToDTO`'s return value is handed back to its caller (`routes/reads.ts`), which decides whether and how to serialize it onto the wire.
- **Retention**: not applicable — this file holds no data across calls.

