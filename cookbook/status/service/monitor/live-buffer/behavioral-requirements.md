
### Constant and Type Shape

- **buffer-capacity-constant**: The module MUST bound the buffer to 200 entries via its internal `CAP` constant (`const CAP = 200`).
- **buffered-deploy-shape**: The exported `BufferedDeploy` interface MUST declare exactly two members: `deploy: ProviderDeploy` (the event as the provider/webhook reported it) and `receivedAt: number` (milliseconds, the server clock's reading at the moment the webhook arrived).
- **module-scope-singleton**: The module MUST hold exactly one buffer array (`const buffer: BufferedDeploy[]`) at module scope, shared by every caller within the same process; it MUST NOT expose a factory, constructor, or any other way to create an independent buffer instance.

### Writing (`pushDeployEvent`)

- **push-appends-with-receipt-time**: `pushDeployEvent(deploy)` MUST append a new `BufferedDeploy` to the end of the buffer, pairing the given `deploy` with a `receivedAt` value read from `Date.now()` at the moment of the call — never from any timestamp carried on `deploy` itself.
- **push-evicts-oldest-beyond-capacity**: after appending, `pushDeployEvent` MUST remove entries from the front of the buffer (the oldest first) whenever the buffer's length exceeds `CAP`, via `buffer.splice(0, buffer.length - CAP)`, so the buffer never holds more than 200 entries.
- **push-returns-void**: `pushDeployEvent` MUST return `void`; it MUST NOT return an identifier, an acknowledgment, or any success/failure signal to its caller.

### Reading (`deployEventsSince`)

- **filter-inclusive-lower-bound**: `deployEventsSince(sinceMs)` MUST return every buffered `BufferedDeploy` whose `receivedAt` is greater than or equal to `sinceMs`, and MUST exclude every entry whose `receivedAt` is strictly less than `sinceMs`; the comparison is inclusive at the boundary (`b.receivedAt >= sinceMs`).
- **filter-preserves-insertion-order**: the array `deployEventsSince` returns MUST preserve the buffer's insertion order (oldest matching entry first), since it is produced by `Array.prototype.filter` over the buffer with no additional sort.
- **filter-is-read-only**: `deployEventsSince` MUST NOT remove, mark, or otherwise mutate any buffered entry, matched or not; two calls with the same `sinceMs` and no intervening `pushDeployEvent` or `clearDeployEvents` call MUST return equal results.

### Resetting (`clearDeployEvents`)

- **clear-empties-buffer**: `clearDeployEvents()` MUST truncate the buffer to zero length (`buffer.length = 0`), discarding every currently buffered entry regardless of its `receivedAt`.
- **clear-is-idempotent**: calling `clearDeployEvents()` when the buffer is already empty MUST leave it empty and MUST NOT raise an error.

### Persistence and Multi-Instance Scope

- **buffer-is-in-memory-only**: every buffered entry MUST exist only in process memory; the module MUST NOT write to disk, a database, or any other durable store, and a process restart MUST lose every entry the buffer held. This is a deliberate durability floor, not an oversight: the module's own comment states the persisted deploy row (written separately, by `hooks.ts`, before it calls `pushDeployEvent`) is the durable copy, and this buffer only ever shortens the latency of seeing it.
- **per-instance-scope-on-multi-instance-deployment**: on a deployment topology with more than one live process instance (the module's own comment names Vercel serverless, one instance per warm lambda), each instance's buffer MUST be independent; a `pushDeployEvent` call on one instance MUST NOT become visible to a `deployEventsSince` call served by a different instance. This is BEST-EFFORT by the module's own accounting, not a documented gap — the accepted mitigation is the caller's own periodic provider poll (60 seconds, external to this file), which independently re-reads authoritative provider state and recovers anything a given instance's buffer failed to deliver.

### Ordering, Concurrency, and Side Effects

- **synchronous-single-threaded-execution**: `pushDeployEvent`, `deployEventsSince`, and `clearDeployEvents` MUST each execute to completion synchronously, with no `await` and no asynchronous step between reading and mutating the shared `buffer` array; within a single process, JavaScript's single-threaded execution model MUST make any two calls into this module run to completion one at a time, with no interleaving of one call's read/splice with another's — this is a fact of the runtime, not a lock this module implements.
- **no-external-side-effects**: the three exported functions MUST NOT perform a network call, a file-system operation, a database call, or emit a process signal or notification of any kind; their only observable effect outside their own return value is mutating the shared module-scope `buffer` array.

