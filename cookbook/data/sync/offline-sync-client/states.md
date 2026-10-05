
The engine runs one cycle at a time; a coalesced kick runs a follow-up cycle
after the current one returns. The engine internally serializes its work, so
these are logical phases of a single cycle, not concurrent states.

| State | Entry condition |
|---|---|
| Idle | No cycle running. Emitted (`idle`) after a full pull + push cycle completes with no error, and the resting state between cycles. |
| Pulling | A kick (`periodic`/`connectivityRestored`/`manual`/`hostSpecific`) started a cycle; the pull phase reads the stored cursor and fetches a page. Loops while `hasMore`, applying each batch atomically before the next request. |
| Reconciling | Every pull iteration, before applying a batch: the effective manifest is diffed against the store's registrations — disappearances purge, schema bumps purge, appearances/bumps on a non-fresh cursor reset the mirror. |
| Resyncing | A reconcile reset fired (appearance/schema-bump on a non-fresh cursor), or the server returned an HTTP 410 (resync required): mirror + cursor cleared, outbox preserved, full re-pull from a nil cursor (`resyncPerformed`). |
| Pushing | The pull phase finished; the push phase drains the outbox in configured batches, resolving each result (applied/conflict/rejected) and looping until the outbox is empty. |
| AuthRequired | The transport returned an HTTP 401 (unauthorized); the engine pauses (`authRequired`) and only a manual kick resumes it. |
| Backing-off | A transport/5xx failure, a bounded-guard trip (`pushMadeNoProgress`, `pullMadeNoProgress`, `manifestUnstable`), or a repeated HTTP 410 scheduled an exponential-backoff retry (`failed`, then a `periodic` kick after `min(baseBackoff · 2^(n−1), maxBackoff)` for the n-th consecutive failure). |

