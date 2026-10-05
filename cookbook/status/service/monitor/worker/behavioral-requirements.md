
### Boot Preconditions

- **worker-thread-required**: The module MUST throw an `Error` with the message `monitor worker must be spawned via worker_threads (see worker-client.ts)` synchronously, during module evaluation, when `parentPort` is `null`.
- **connection-url-required**: The module MUST throw an `Error` with the message `monitor worker spawned without workerData.db.url (see MonitorWorkerData)` when `workerData` is `null`/`undefined`, or `workerData.db` is `null`/`undefined`, or `workerData.db.url` is falsy.
- **config-required**: The module MUST throw an `Error` with the message `monitor worker spawned without workerData.config (see MonitorWorkerData)` when `workerData.config` is falsy.
- **boot-checks-run-in-order**: The module MUST evaluate the `parentPort` check, then the `db.url` check, then the `config` check, in that exact order, and MUST NOT call `openLibsql` until all three checks have passed.
- **migrations-not-run-here**: The module MUST NOT run database migrations itself; it treats the schema as already migrated by the host's main thread before this worker was spawned, per its own comment: "Migrations already ran on the main thread before this worker was spawned."

### Connection Lifecycle

- **connection-opened-once**: The module MUST call `openLibsql(conn)` exactly once per worker instance, at module-evaluation time, after the boot preconditions pass and before attaching any `message` listener.
- **concurrency-tuning-applied-once**: The module MUST `await tuneDbForConcurrency(db, conn)` exactly once, immediately after `openLibsql`, before constructing storage or attaching the `message` listener.
- **storage-built-once-reused**: The module MUST call `createLibsqlStorage(db, conn)` exactly once and MUST reuse the resulting `Storage` value for every `CycleRequest` this worker instance receives; it MUST NOT rebuild storage per message.
- **no-explicit-close**: The module MUST NOT explicitly close, checkpoint, or otherwise release the connection it opened; the connection's lifetime is bound to the worker thread's own lifetime.

### Cooldown Adoption

- **cooldowns-attached-before-listening**: The module MUST call `attachCooldownState(cooldowns)` with the `cooldowns` field read from `workerData`, and MUST do so before attaching the `message` listener.
- **cooldowns-optional**: When `workerData.cooldowns` is `undefined`, the module MUST proceed without throwing; `attachCooldownState`'s own guard (`if (buffer) slots = new BigInt64Array(buffer)`) leaves the module's private, thread-local cooldown registry in place rather than blocking startup.

### Message Protocol

- **one-listener-registered**: The module MUST register exactly one `message` listener on `parentPort`, once, after connection setup and cooldown adoption complete.
- **reply-echoes-seq**: For every `CycleRequest` message received, the module MUST post back exactly one `CycleReply` whose `seq` field equals the received message's `seq` field, unchanged.
- **fullsync-passed-through**: The module MUST pass the received message's `fullSync` field, unchanged, as `runMonitorCycle`'s `opts.fullSync` argument.
- **storage-and-config-passed-unchanged**: The module MUST pass the single shared `storage` value built at boot as `runMonitorCycle`'s first argument, and MUST pass the `config` value captured from `workerData` at boot, unchanged, as `opts.config`, for every `CycleRequest` the worker processes.
- **success-reply-shape**: When the `runMonitorCycle` call resolves, the module MUST post back `{ seq, ok: true }` with no `error` field.
- **failure-reply-shape**: When the `runMonitorCycle` call rejects, the module MUST post back `{ seq, ok: false, error }`, where `error` is the rejection value's `message` property when that value is an `Error` instance, and `String(err)` otherwise.
- **cycle-failure-does-not-crash-worker**: A rejected `runMonitorCycle` call MUST NOT cause the module to throw, exit, or stop listening for further `message` events; the worker MUST remain able to process a subsequent `CycleRequest` after replying `{ ok: false }` to a failed one.

### Credential Handling

- **credentials-held-in-memory-only**: The module MUST hold `conn.authToken` and every field of `config` — including `config.credentials` and `config.secrets` — only in module-scope bindings (`conn`, `config`) for the lifetime of the worker thread; it MUST NOT write any of these values to disk, to a log call, or to a `CycleReply`.
- **credentials-cross-once-via-workerdata**: The module MUST obtain `conn` and `config` exclusively from the single destructure of `workerData` performed at module evaluation; it MUST NOT request, fetch, or otherwise read either value through any other channel while the worker is running.

