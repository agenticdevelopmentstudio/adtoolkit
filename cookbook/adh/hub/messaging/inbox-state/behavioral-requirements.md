
**Shared wake channel**

- **shared-stream-refcounting**: subscribing to the wake channel MUST open the single shared live
  connection to the notification stream endpoint only on the transition from zero to one
  subscriber, and unsubscribing MUST close that connection only on the transition from one
  subscriber back to zero; a second, third, or later subscriber MUST NOT open an additional
  connection.
- **local-change-broadcast**: broadcasting a wake signal MUST invoke every function currently in
  the subscriber set, synchronously and with no arguments.
- **wake-signal-carries-no-payload**: the shared connection's event and poll handling MUST both
  reduce to the same wake broadcast; a `notification` server event's payload MUST NOT be parsed,
  inspected, or passed to subscribers — receipt of the event is the entire signal; the wake
  payload itself is ignored.

**Unread count**

- **unread-count-fetch-on-mount-and-wake**: the unread-count state MUST issue `GET
  {API_BASE}/unread-count` once on mount and once on every subsequent wake delivered through the
  wake channel, and MUST set `count` to the resolved `count` field each time.
- **unread-count-preserved-on-failure**: a rejected `GET {API_BASE}/unread-count` MUST leave the
  previously set `count` unchanged; the unread-count state MUST NOT reset `count` to `0` or to any
  other value on a failed fetch.

**Notification inbox**

- **inbox-query-serialization**: building the inbox query string MUST set `status`, `read`,
  `page`, and `pageSize` query parameters only when the corresponding query field is provided,
  and MUST append one repeated `category=<c>` parameter per entry of the categories list, in that
  list's order; a query with every field omitted MUST serialize to the empty string.
- **inbox-status-left-to-backend-default**: when the `status` query field is not provided,
  building the inbox query string MUST omit the `status` parameter entirely rather than
  substituting a client-side default; this "defaults to the caller's inbox" on the backend, not
  in this logic.
- **inbox-fetch-per-query-and-nonce**: the notification inbox state MUST re-issue `GET {API_BASE}`
  (with the built query string appended when non-empty) whenever the built query string changes or
  a refetch or a mutation increments the internal reload counter, and MUST set `items`/`total`
  from the resolved `{ items, total, page, pageSize }` body on success.
- **inbox-stale-response-ignored**: if the query or reload counter changes again — or the state is
  torn down — before an in-flight `GET {API_BASE}` request resolves, the notification inbox state
  MUST NOT apply that request's resolution (success or failure) to `items`, `total`, `loading`, or
  `error`.
- **inbox-refetch-on-wake**: the notification inbox state MUST re-issue its fetch on every wake
  delivered through the wake channel, in addition to the query/counter-driven refetch above.
- **inbox-mutation-then-broadcast**: the mark-read, mark-unread, archive, trash, and read-all
  actions MUST each `POST` to a distinct path built from `{API_BASE}` (`/<id>/read`, `/<id>/unread`,
  `/<id>/archive`, `/<id>/trash`, and `/read-all` respectively, with `id` percent-encoded) and, on
  success, MUST broadcast a wake signal exactly once — refetching both this state's own list and
  every other mounted messaging state, including the unread count.
- **inbox-mutation-failure-leaves-list-untouched**: if a mutation's `POST` rejects, the
  notification inbox state MUST NOT broadcast a wake signal and MUST NOT modify `items` itself;
  the affected row remains exactly as it was before the call — correct rather than optimistic.

**DM conversation list**

- **dm-inbox-initial-window**: on mount, the DM conversation list state MUST request `GET
  {DM_BASE}?pageSize=100` (`DM_PAGE_SIZE`).
- **dm-inbox-window-growth-and-ceiling**: each call to the load-more action MUST increase the
  requested window by `DM_PAGE_SIZE` (100) up to a ceiling of `DM_MAX_LIMIT` (500) — the new window
  size is `min(current + 100, 500)`; the load-more action MUST NOT issue an offset-based follow-up
  request — the next refresh re-requests the single, larger window from
  `{DM_BASE}?pageSize=<newLimit>`.
- **dm-inbox-presence-merge**: for every chat row returned, the DM conversation list state MUST
  merge that row's `online`/`lastSeenAt` from a single `GET {PRESENCE_BASE}` call keyed by
  `chat.otherUserId`, falling back to `online: false, lastSeenAt: null` when no presence record is
  returned for that user id.
- **dm-inbox-presence-query-encoding**: the presence fetch MUST request `GET {PRESENCE_BASE}
  ?userIds=<enc(ids)>` where `ids` is the deduplicated, falsy-filtered list of `otherUserId`
  values joined with `,` and the ENTIRE joined string is percent-encoded as one unit — a comma
  inside the joined list is itself percent-escaped, not left literal.
- **dm-inbox-presence-failure-is-silent**: if the presence fetch rejects, the DM conversation list
  state MUST proceed with every chat's `online`/`lastSeenAt` defaulted to `false`/`null` rather
  than failing the whole load or surfacing an `error`.
- **dm-inbox-stale-response-discarded**: the DM conversation list state MUST track a generation
  counter, incremented on every new load and on teardown, and MUST discard (apply neither the
  success nor the failure branch of) any load whose generation is no longer the current one when
  it settles.
- **dm-inbox-refetch-on-wake**: the DM conversation list state MUST re-request its current window
  on every wake delivered through the wake channel.
- **dm-inbox-load-failure-keeps-last-good-list**: a rejected load MUST set `error` to a message but
  MUST NOT clear or replace the previously loaded `chats` array.
- **dm-inbox-has-more-computation**: `hasMore` MUST be `true` only when the loaded `chats.length`
  is less than the server-reported `total` AND the current window `limit` is still below
  `DM_MAX_LIMIT`; reaching the 500-row ceiling MUST report `hasMore: false` even if `total` is
  larger, since no request is made past that ceiling.

**A single DM thread**

- **dm-thread-null-chatid-clears-state**: when `chatId` is `null` or the empty string, the DM
  thread state MUST set `messages` to `[]` and `loading` to `false`, and MUST NOT issue any
  request or open any connection.
- **dm-thread-history-load-and-sort**: for a non-empty `chatId`, the DM thread state MUST request
  `GET {DM_BASE}/<enc(chatId)>/messages?pageSize=200` and MUST merge the returned `items`, sorted
  ascending by `seq`, into `messages`.
- **dm-thread-message-merge-dedupe**: every point where a message enters `messages` — the initial
  history load, the live stream, and the poll fallback — MUST go through the same merge step,
  which MUST discard an incoming message whose `id` already exists in the list and otherwise MUST
  append it and re-sort the full list ascending by `seq`.
- **dm-thread-sse-cursor-from-last-loaded-seq**: after the history load resolves, the DM thread
  state MUST open a live connection at `GET {DM_BASE}/<enc(chatId)>/stream?after=<afterSeq>`,
  where `afterSeq` is the `seq` of the last (highest) loaded message, or `0` when no messages
  were loaded.
- **dm-thread-malformed-frame-ignored**: a live-stream event whose `data` fails to parse as JSON
  MUST be dropped without updating `messages` and MUST NOT throw out of the event handler.
- **dm-thread-teardown-on-change-or-unmount**: on `chatId` change or unmount, the DM thread state
  MUST mark itself cancelled and MUST close the stream/poll handle, so neither the pending history
  fetch nor the connection can update state afterward.
- **dm-thread-poll-fallback-refetch**: the poll fallback MUST re-request the same `GET
  {DM_BASE}/<enc(chatId)>/messages?pageSize=200` window and merge its `items` the same way as the
  initial load; a failed poll refetch MUST be swallowed, leaving `messages` unchanged.
- **dm-thread-send-noop-on-empty-or-missing-chat**: the send action MUST trim the message body
  and, when `chatId` is absent or the trimmed text is the empty string, MUST return without
  issuing any request.
- **dm-thread-send-client-message-id**: the send action MUST generate a `clientMessageId` using a
  random-UUID generator when one is available, and MUST otherwise generate one from the current
  timestamp and a random suffix, before `POST`-ing `{ body, clientMessageId }` to
  `{DM_BASE}/<enc(chatId)>/messages`.
- **dm-thread-send-merges-and-broadcasts**: on a successful send, the DM thread state MUST merge
  the server-returned message into `messages` via the same merge step and MUST broadcast a wake
  signal exactly once.
- **dm-thread-send-propagates-failure**: a rejected send request MUST propagate the rejection to
  the caller unchanged; the send action MUST NOT catch or convert it.
- **dm-thread-mark-read-request-shape**: the mark-read action MUST return without a request when
  `chatId` is absent, and otherwise MUST `POST` a literal `{}` JSON body to
  `{DM_BASE}/<enc(chatId)>/read` and then broadcast a wake signal exactly once.
- **dm-thread-ownership-comparison**: the ownership check MUST return `true` only when the
  caller's id (from the signed-in session) is non-null AND strictly equals `msg.senderUserId`; it
  MUST return `false` whenever the caller's id is `null`, regardless of `msg.senderUserId`.

**Starting a DM**

- **start-dm-request-shape**: the start-DM action MUST `POST { recipientId }` to `{DM_BASE}` and,
  on a successful response, MUST resolve to `{ chatId: res.id }`.
- **start-dm-forbidden-mapping**: the start-DM action MUST catch a typed HTTP error with status
  `403` and resolve to `{ forbidden: true }` instead of rejecting.
- **start-dm-other-errors-propagate**: any error other than a `403` typed HTTP error (including
  any other HTTP status or a network-level failure) MUST propagate out of the start-DM action as
  a rejection.

### Security

This is a security-relevant recipe: it transmits a bearer session credential, and the
live-connection path carries that credential in a URL rather than a header.

- **auth-delegated-to-shared-client**: every plain HTTP call in this recipe MUST go through the
  shared authenticated request client, which attaches `Authorization: Bearer <token>` from the
  stored access token; neither the DM logic nor the notification logic reads, stores, or attaches
  a token itself for its plain HTTP calls.
- **session-refresh-waterfall**: a `401` on any plain HTTP call in this recipe MUST trigger exactly
  one token refresh and one retried request, inherited unconditionally from the shared request
  client; a second `401` on the retry MUST propagate as a thrown typed HTTP error with `status:
  401`.
- **errors-carry-status-and-code**: any non-2xx response other than an unresolved `401` MUST cause
  the call to throw a typed HTTP error, carrying the response's HTTP status and, when the body
  supplies one, a machine-readable `code`.
- **sse-token-rides-the-query-string**: both the DM thread's live connection
  (`.../stream?after=...`) and the shared notification stream (`/api/notifications/stream`) MUST
  be opened with the live access token appended as an `access_token` query parameter, because the
  underlying live-connection transport cannot set a request header; this is a deliberate deviation
  from the header-based scheme every other call in this recipe uses.
- **sse-token-read-fresh-per-attempt**: the live-connection transport MUST read the stored access
  token on every connection attempt (the initial open and each retry after a hard close), not once
  at state-initialization time, so a token refreshed by the poll fallback's own requests is
  picked up on the next reconnect attempt.
- **no-stream-without-a-token**: the live-connection transport MUST NOT open a live connection when
  no access token is available; it MUST fall back to the interval-and-focus poll instead, which
  keeps retrying to open the connection on each tick.
- **poll-fallback-uses-the-bearer-header**: unlike the live-connection path, the poll fallback's
  own requests (the DM thread's refetch and the notification logic's wake-driven refetches) MUST
  carry the token via the `Authorization` header through the shared request client, not in the
  URL.
- **presence-visibility-is-server-gated**: the presence lookup's response is documented as
  reporting `{ online: false, lastSeenAt: null }` for a hidden or absent target; this recipe
  performs no visibility check of its own — the guarantee that real state never leaks is enforced
  entirely by the `/api/presence` backend.

