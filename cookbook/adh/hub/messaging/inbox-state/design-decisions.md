
**Decision**: the shared wake channel opens exactly one `/api/notifications/stream` connection,
refcounted across every mounted messaging hook, rather than each hook opening its own.
**Rationale**: the source's own comment in `use-notifications.ts` states this directly — a page
with the header bell, the DM list, and an open inbox previously held two to three duplicate wake
connections before this refactor; refcounting on a module-level `Set` keeps one connection alive
exactly as long as at least one hook needs it.
**Approved**: pending

**Decision**: the DM conversation list grows a single window (`loadMore` widening one `pageSize`
request) instead of accumulating separate offset pages.
**Rationale**: the source's own comment explains this keeps each fetch "one consistent snapshot" —
accumulating offset pages independently would let a chat that reorders between page fetches
(`updated_at`-sorted) produce a duplicate or dropped row across the page boundary.
**Approved**: pending

**Decision**: the presence fetch failing is treated as "assume everyone offline" rather than
failing the whole conversation-list load.
**Rationale**: the source's own comment on `fetchPresenceMap` calls this out explicitly as
best-effort, because a transient presence-service blip must not blank the entire DM inbox; this
recipe records that asymmetry (the chats list is essential, presence is decorative) as intentional.
**Approved**: pending

**Decision**: the DM thread's live connection and the shared notification stream's connection both
carry their access token in the URL query string instead of a header, unlike every other request
in this recipe.
**Rationale**: both source files say so directly; this recipe documents the resulting exposure
difference under Security and Privacy rather than treating it as an oversight to silently correct.
Platform scope: Web — this is the browser `EventSource`'s own platform limitation (it cannot set
request headers); a live-connection client on another platform that can set a header need not
replicate this deviation.
**Approved**: pending

**Decision**: `send` and `markRead` carry no chatId-generation guard, while the thread's own history
load and `useDmConversations`' window load both do.
**Rationale**: recorded as observed source behavior, not smoothed over — see the
`thread-message-bleed-on-chatid-switch` marker; a port MUST decide deliberately whether to add
a matching guard to these two callbacks or to preserve the current behavior, since the current
checkout does not settle which is intended.
**Approved**: pending

**Decision**: a send that settles after a `chatId` switch can merge its message into the newly displayed thread; the send and mark-read actions have no generation guard.

**Rationale**: the thread's `messages` is one array not partitioned by chat id, unlike the history load's cancellation flag and the conversation list's generation counter; closing the gap takes a generation guard (or per-chat partitioning) on send and mark-read, and it is undecided whether product intent tolerates the bleed-through during a fast switch.

**Approved**: pending

