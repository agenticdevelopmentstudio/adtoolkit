
- **Data collected**: this component transports reaction rows — each carrying a `customerId` (the user who reacted), a `targetKind`/`targetId` (the subject reacted to), and an `emoji` — none of which this module collects itself; it only reads and writes rows the backend already stores. Per the module's own top-of-file comment, this read is not actor-scoped: "the list is PUBLIC within the ecosystem (everyone sees who reacted)."
- **Storage**: not applicable — `reactions.ts`/`wire.ts` persist nothing themselves; every method is a stateless fetch call.
- **Transmission**: every request travels over whatever transport `authedJson`/`authedRequest` use (outside these given sources); this component configures no TLS or transport-level behavior itself.
- **Retention**: not applicable — this component defines no retention policy of its own; retention of reaction rows (including the soft-delete `deletedAt` field the read routes already filter out, per `wire.ts`) is entirely the backend's concern.

