
- **Null and empty input — `chatId`**: `dm-thread-null-chatid-clears-state` above; a `null` and an
  empty-string `chatId` are treated identically — MUST.
- **Null and empty input — send body**: `dm-thread-send-noop-on-empty-or-missing-chat` above; a
  body that is empty or all whitespace after trimming MUST NOT be sent.
- **Null and empty input — presence ids**: the presence lookup MUST return an empty map without
  issuing any request when its deduplicated, falsy-filtered id list is empty.
- **Null and empty input — inbox categories**: an absent or empty categories list MUST produce
  no `category=` query parameters at all, per `inbox-query-serialization`.
- **Boundary values — DM window ceiling**: `dm-inbox-window-growth-and-ceiling` and
  `dm-inbox-has-more-computation` above; the window never exceeds 500 rows and `hasMore` reports
  `false` once it does, even if more rows exist server-side — 500 is the ceiling the backend also
  caps at.
- **Boundary values — DM thread window**: neither the initial load nor the poll fallback in the
  DM thread state requests more than `pageSize=200`, and the state exposes no further-back
  pagination for thread history (unlike the conversation list's load-more action); a thread with
  more history than the current window simply never surfaces it through this state — a fact, not
  a gap, since no history-paging action exists to fail.
- **Concurrent access — DM conversation list**: `dm-inbox-stale-response-discarded` above; the
  generation counter guarantees only the most recently issued load's result is ever applied.
  Concurrent execution here is single-threaded, so the check-and-increment on the generation
  counter cannot itself race.
- **Concurrent access — DM thread history vs. live stream**: the live connection is opened only
  after the history load resolves, cursored at the last loaded `seq`; the connection is a
  cursor-based replay (`after=<seq>`), not a from-now push, so a message sent by another
  participant during the gap between the history response and the connection opening is still
  delivered once the connection connects.
- **Concurrent access — send during a thread switch**: see the
  `thread-message-bleed-on-chatid-switch` edge case below.
- **Error states — plain HTTP failure**: any plain HTTP call's rejection propagates as a thrown
  typed HTTP error (or a plain error for a non-HTTP failure); each piece of state that exposes an
  `error` field sets it from the error's message, and each direct caller action (send, mark-read,
  the mutations, start-DM) lets the rejection propagate to the caller instead.
- **Error states — malformed live-stream frame**: `dm-thread-malformed-frame-ignored` above.
- **Error states — presence fetch failure**: `dm-inbox-presence-failure-is-silent` above.
- **Offline or disconnected state**: the poll fallback (interval + window-focus) is the only
  reconnection behavior this recipe relies on; nothing here checks a live network-connectivity
  signal or queues a send/mutation for retry once connectivity returns — a send issued while
  offline simply rejects with a network-level failure and is not retried or queued by this recipe.
- **No timeout**: no call in this recipe sets a deadline or cancellation signal; a
  reachable-but-unresponsive backend leaves that call pending indefinitely.
- **No cancellation**: no exposed action (send, mark-read, the mutations, load-more, start-DM)
  accepts a cancellation signal; a caller cannot cancel an in-flight call through this state.
- **No retry beyond the 401 waterfall**: every plain HTTP call issues exactly one request (plus,
  on a `401`, the single inherited refresh-and-retry); nothing in this recipe retries a network
  failure or a non-401 error status, and no exponential backoff exists anywhere in this recipe —
  the poll fallback is a fixed interval, not a backoff schedule.
- **thread-message-bleed-on-chatid-switch**: if the send action (or its returned promise) is still
  pending when `chatId` changes, the DM thread state's `messages` is a single array not
  partitioned by chat id, and neither the send action nor the mark-read action carries a
  generation guard analogous to the history load's own cancellation flag or the DM conversation
  list's generation counter; the resolved message MAY merge into whatever thread is displayed when
  it settles rather than the one it was sent for.

