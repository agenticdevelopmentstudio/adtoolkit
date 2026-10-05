
- **Empty body**: A response with a zero-byte body MUST succeed under any
  limit of zero or more, returning an empty body paired with the response —
  the running total (0) never exceeds a non-negative limit. MUST.
- **Zero or negative limit**: A limit of zero or less MUST cause the
  transfer to be refused as too-large as soon as either the declared-length
  check (true for almost any declared length once the limit is
  non-positive) or the first non-empty chunk pushes the running total past
  that ceiling; a response that sends no bytes and declares no length
  would still succeed as an empty body. MUST.
- **Exact-boundary body**: A body of exactly limit bytes MUST be accepted
  in full; a body of limit + 1 bytes, with no declared-length header to
  short-circuit the declared-length check, MUST be refused by the running
  check alone. MUST.
- **Concurrent transfers on one loader**: Multiple simultaneous calls to
  read a body on the same loader instance MUST each receive independent
  bookkeeping keyed by their own transfer's identifier under the shared
  lock; one transfer overflowing its limit MUST NOT affect another
  concurrent transfer's buffer, limit, or outcome. MUST.
- **Unreachable host / DNS or TLS failure**: When the underlying connection
  never succeeds, the transport reports the failure through its completion
  callback, and the loader MUST rethrow that error unchanged rather than
  reporting it as too-large or swallowing it. MUST.
- **Connectivity lost mid-transfer (offline/disconnected)**: If the network
  drops after some chunks arrived but before completion, and the running
  total had not yet crossed the limit, the loader MUST rethrow the
  resulting transport error and MUST NOT return the partial body collected
  so far — a transfer that does not finish MUST NOT hand back a partial
  result. MUST.
- **A cancellation racing an overflow**: If the calling context is
  cancelled at the same moment the running check would have overflowed,
  either outcome (a cancellation error or the too-large failure) is
  acceptable; the design does not order the two, and completion is only
  ever signaled once per transfer, so exactly one of them MUST reach the
  caller — not both, and not neither. MUST.
- **Deallocation with a transfer in flight**: If the loader is disposed of
  while a transfer is outstanding, disposal MUST let that transfer's task
  run to completion and resume normally, since the callback object and
  shared state it still needs are retained by the transport session
  itself, independent of the loader. MUST.

