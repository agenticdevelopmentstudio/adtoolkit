
### Storage Location

- **fallback-token**: The fallback token MUST be the string `"AgenticToolkit"`.
- **token-filter**: The token-deriving operation MUST return the display name with every character that is not a letter, mark, or number removed, with no substitute character inserted.
- **token-order**: The token-deriving operation MUST keep the surviving characters in their original order and original case.
- **token-empty-fallback**: The token-deriving operation MUST return the fallback token when no character survives the filter, including for an empty input.
- **token-non-ascii**: The token-deriving operation MUST keep non-ASCII letters and digits (the filter matches any letter, mark, or number, not just ASCII ones), so `"Café"` stays `"Café"`.
- **display-name-source**: The display-name reader MUST read the app's declared display name from platform bundle metadata, resolved through the platform's own localization mechanism when the app localizes that value.
- **display-name-fallback**: The display-name reader MUST return the fallback token when the platform's declared display name is absent, is not a string, or is the empty string; absent and empty are the same answer.
- **display-name-unfiltered**: The display-name reader MUST return the name unfiltered ("spaces and all"); filtering happens only in the token-deriving operation.
- **running-token**: The default token MUST equal the token-deriving operation applied to the display name.
- **directory-shape**: The storage-directory operation MUST return the given home directory with one path component appended: `"."` followed by the token lowercased.
- **directory-case-fold**: The storage-directory operation MUST return the same location for two tokens that differ only in letter case.
- **directory-default-token**: The storage-directory operation MUST default its token argument to the default token.
- **directory-no-io**: The storage-directory operation MUST NOT touch the filesystem; it neither creates nor checks the directory.
- **shared-directory-distinct-files**: Each store MUST pick its own filename inside the shared directory and MUST NOT name that file after the token (naming it after its own contents instead); two stores MUST NOT share a file.

### Bounded Database: Construction

- **init-signature**: Constructing a bounded database MUST take a file path, a reader count (default `3`), a read deadline (default 10 seconds), a write deadline (default 60 seconds), a busy timeout in seconds (default `5`), and an optional prepare hook — a function that receives the raw connection and may raise (default none).
- **init-throws**: Construction MUST raise whatever the underlying database library raises while opening the database; it defines no error of its own for construction.
- **reader-count**: Construction MUST pass the reader count unchanged as the underlying database library's reader-count setting; this source does not validate it, and the behavior for values below 1 is owned by that library.
- **busy-mode**: Construction MUST configure every connection to wait up to the busy timeout, in seconds, on a locked database before failing.
- **temp-store-memory**: Every connection MUST apply a temp-store-in-memory setting at open, before the caller's prepare hook runs.
- **prepare-order**: The caller's prepare hook MUST run on every connection at open, after the temp-store setting and before the ejection mechanism is installed.
- **prepare-failure**: An error raised by the prepare hook MUST propagate out of the connection open (out of construction for the writer, out of the first read that opens a new reader).
- **ejection-installed**: Every connection MUST have the ejection mechanism installed at open without the caller asking for it.
- **file-backed-pool**: For any path other than exactly `":memory:"`, construction MUST open a write-ahead-logged, pooled connection at that path, giving one writer connection and up to the configured reader count of reader connections.
- **in-memory-queue**: For a path of exactly `":memory:"`, construction MUST open a single shared connection, so reads and writes share one connection; ejection and metrics MUST still apply.
- **writer-exposed**: The bounded database MUST expose the underlying writer connection object for direct access to the underlying database library; access through it bypasses deadlines and metrics.
- **no-directory-creation**: Construction MUST NOT create the parent directory of the path; a missing directory surfaces as the underlying database library's open error.

### Bounded Database: Operations

- **write-transaction**: The write operation MUST run its body on the writer connection inside a transaction and return its result; a failure from the body MUST roll the transaction back and propagate.
- **read-reader**: The read operation MUST run its body on a reader connection and return its result; a reader MUST see every write committed before it started.
- **read-concurrency**: Top-level reads on a file-backed database MUST NOT wait for the writer; up to the configured reader count of them MAY run in parallel.
- **write-serialised**: Top-level writes MUST be serialised on the single writer connection.
- **write-no-transaction**: The transaction-free write operation MUST run its body on the writer connection without opening a transaction, for bodies that issue their own begin/commit or run statements that cannot sit inside one (such as attaching another database file or reclaiming space).
- **open-transaction-rollback**: When a top-level transaction-free write's body returns or fails with a transaction still open, the database MUST roll that transaction back after the deadline is disarmed and before the connection is returned to the pool.
- **rollback-failure**: The safety-net rollback MUST be issued in a way that discards its own failure: if it fails, the error is lost, no signal reaches the caller or the metrics, and the writer connection returns to the pool still inside a transaction.
- **default-deadlines**: A top-level read with no explicit deadline MUST use the configured read deadline; a top-level write or transaction-free write with no explicit deadline MUST use the configured write deadline.
- **explicit-deadline**: An explicit deadline on a top-level call MUST replace the default for that call only.
- **synchronous-calls**: Every operation MUST be synchronous: it blocks the calling thread until its body finishes and returns the value or raises.

### Bounded Database: Ejection

- **deadline-clock**: The deadline MUST be measured on a monotonic clock, so a wall-clock step backward or a sleep/wake cannot stop ejection.
- **deadline-armed-on-connection**: The deadline MUST be armed after the connection is acquired and disarmed before any cleanup, so time spent waiting for the writer or a reader slot does not count against it and cleanup cannot itself be ejected.
- **non-positive-deadline**: A zero or negative deadline MUST eject at the first progress check instead of trapping.
- **progress-interval**: The ejection check MUST run every 1000 low-level execution steps on the statement's own thread and MUST abort the statement once the current monotonic time is at or past the armed deadline.
- **no-deadline-no-abort**: The ejection check MUST allow the statement to continue when no deadline is armed on the current thread, so statements run through direct writer access are never ejected.
- **eviction-error**: A top-level call whose statement is aborted by the deadline MUST raise the deadline-exceeded error, carrying a lane name of `"read"` for a read and `"write"` for a write or transaction-free write, and the elapsed milliseconds since the call began.
- **eviction-replaces-error**: The underlying low-level interruption error from an ejected statement MUST be replaced by the deadline-exceeded error; other errors from the body MUST propagate unchanged.
- **swallowed-eviction**: When the body catches the interruption itself and returns normally, the call MUST return that value and record a completion, not an eviction.
- **error-type**: The deadline-exceeded error MUST be a single, comparable value carrying a lane name (`"read"` or `"write"`) and elapsed milliseconds.

### Bounded Database: Reentrancy

- **reentrant-inline**: A read, write, or transaction-free write called on a thread already inside one MUST run its body inline on the enclosing operation's connection instead of re-entering the pool.
- **read-your-writes**: A read nested inside a write MUST see the enclosing write's uncommitted changes.
- **nested-no-transaction**: A nested write MUST NOT open its own transaction or savepoint; it runs inside whatever the enclosing operation has open.
- **nested-deadline-inherited**: A nested call MUST be bounded by the enclosing operation's armed deadline; its own deadline argument MUST be ignored.
- **nested-eviction-error**: An ejection inside a nested call MUST raise the deadline-exceeded error with the nested call's lane and an elapsed value of `0`; the enclosing top-level call then records one eviction on its own lane and re-raises that same error.
- **nested-not-metered**: A nested call MUST NOT change the in-flight, completed, or evicted counters; it is counted by its enclosing operation.
- **is-reentrant**: The reentrancy indicator MUST be true exactly when the calling thread is inside a read, write, or transaction-free write, so a consumer can translate errors only at the outermost boundary.
- **cross-instance-reentrancy**: The current-connection slot MUST be treated as a single per-thread value shared by every bounded database instance: a call on database B made inside an operation on database A runs B's body inline on A's connection, and B's reentrancy indicator reports `true`, even though its documentation says "on this database." Cross-instance nesting is unsupported.

### Bounded Database: Metrics

- **in-flight-accounting**: Each top-level call MUST increment its lane's in-flight counter before acquiring a connection and decrement it when the call ends, whether it returns or raises.
- **completion-record**: A top-level call that returns MUST increment its lane's completed counter and append its duration to the lane's window.
- **eviction-record**: A top-level call that raises the deadline-exceeded error MUST increment its lane's evicted counter and MUST NOT add its duration to the window.
- **other-errors-unrecorded**: A top-level call that raises any other error MUST NOT change the completed counter, the evicted counter, or the window.
- **duration-includes-wait**: The recorded duration MUST run from before connection acquisition to the end of the call, so it includes queueing for the writer or a reader slot.
- **percentile-window**: Each lane MUST compute its 50th- and 99th-percentile durations over at most the 128 most recent completed durations, choosing the sorted element at index `round((count - 1) * q)`, in milliseconds.
- **percentile-empty**: A lane with no completed durations MUST report both percentile values as `0`.
- **stats-shape**: The metrics snapshot MUST hold exactly two lane records in the order `"write"`, then `"read"`, each carrying a lane name, in-flight count, completed count, evicted count, and 50th-/99th-percentile durations.
- **stats-consistency**: The metrics snapshot MUST read both lanes under one lock acquisition, so the snapshot is internally consistent.
- **stats-sendable**: The metrics snapshot and its lane records MUST be plain, comparable data values, safe to pass across threads, with a straightforward public initializer.

### Bounded Database: Concurrency

- **sendable-class**: The bounded database MUST be safe to call concurrently from multiple threads and tasks, relying on the underlying database library's own thread safety for connections, a lock around the metrics, and per-thread state for the current operation's deadline and connection.
- **per-thread-state**: The armed deadline and the current connection MUST be stored per thread, so operations on different threads never observe each other's deadline or connection.

