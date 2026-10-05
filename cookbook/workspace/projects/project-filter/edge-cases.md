
- **Null and empty input**: An empty query short-circuits both operations
  before either inspects the text or the record — finding ranges returns
  no ranges and checking a match returns true (MUST, see
  `empty-query-yields-no-ranges`, `empty-query-matches-every-repo`,
  PF-001, PF-009). Empty text (or an empty name/path on the record) makes
  the scan's starting condition false, so finding ranges returns no ranges
  for any non-empty query (MUST, see `empty-text-yields-no-ranges`).
- **Boundary values**: A query exactly as long as the text, or longer
  than the remaining unsearched portion of the text, causes the
  underlying search to report no match, ending the scan with whatever
  ranges were already found (MUST). A query that overlaps itself when
  repeated in the text (e.g. `"aa"` in `"aaa"`) is under-counted by
  design, not by accident — see `non-overlapping-scan-advance` and
  PF-010 (MUST).
- **Concurrent access**: This component holds no internal state; finding
  ranges and checking a match are pure functions over their
  text/query/record arguments, and any intermediate representation a call
  builds is a fresh, immutable value local to that call. Concurrent calls
  from any thread or execution context MUST be safe with no additional
  synchronization required (MUST, see `stateless-and-pure`).
- **Error states**: Not applicable — no operation here throws, returns a
  value the caller must unwrap, or calls anything that can fail; the one
  not-found signal in the underlying search is turned into a normal loop
  exit, never surfaced to the caller as an error.
- **Offline or disconnected state**: Not applicable — this component
  performs no network call and depends on no connectivity; it operates
  only on in-memory text values already held by the caller.
- **Missing file or unreachable server**: Not applicable — this component
  performs no file-system or network I/O of its own; a record's path is a
  string it compares textually, never a path it opens, stats, or reads.
- **Cancellation and timeouts**: Not applicable — every call to finding
  ranges and checking a match is synchronous; neither operation spawns a
  subprocess or a long-running task that something else could cancel or
  that could time out (MUST, see `ranges-loop-terminates` for the bound
  on how long a single call can run).
- **Concurrent calls with different arguments**: Because both operations
  are pure and stateless, two callers invoking finding ranges or checking
  a match with different query/text/record arguments at the same time on
  different threads MUST each observe only their own inputs and outputs,
  with no cross-talk between the two calls (MUST, see
  `stateless-and-pure`).

