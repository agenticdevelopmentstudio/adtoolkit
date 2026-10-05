
### Data Shape

- **issue-alert-shape**: An alert value MUST carry exactly six fields: a `kind` of `opened`, `resolved` or `retired`, `target`, `name`, `environment` (string or absent), `state` (string or absent), and `detail` (string or absent); the module MUST provide no way to construct a value missing any of these six fields or carrying an unrecognized `kind`.
- **retired-kind-distinct-from-resolved**: The `kind` value `retired` MUST be distinct from `resolved`: `retired` records that the monitor was deleted because what it watched stopped existing — an automatic removal — which is distinct on purpose from `resolved`: nothing recovered, so claiming it did would tell on-call an outage cleared when it never did, yet the `opened` alert sent earlier still needs a counterpart, or the last word anyone hears about that target is a red one no future cycle can ever close.

### Queueing

- **enqueue-synchronous**: The enqueue operation MUST append the given alert to the shared queue synchronously and return nothing, performing no wait and no I/O.
- **enqueue-independent-of-flush-config**: The enqueue operation MUST accept and queue an alert regardless of whether alert delivery is currently enabled. Whether delivery is actually turned on is the flush operation's call to make (it takes the destination); an alert dropped at enqueue time while delivery is off would leave an `opened` alert sent earlier with no `resolved`/`retired` counterpart once delivery turns back on.
- **queue-bounded-drop-oldest**: When appending a new entry would grow the queue past `MAX_QUEUED` (100) entries, the enqueue operation MUST drop the single oldest queued entry immediately after the append, so the queue never holds more than 100 entries.

### Delivery

- **flush-noop-null-url**: The flush operation MUST return, without dequeuing or sending anything, when its destination argument is `null`; every currently-queued alert MUST remain queued for a later flush.
- **flush-noop-empty-queue**: The flush operation MUST return without making any network call when the queue is empty, regardless of the destination.
- **flush-drains-before-sending**: When the destination is non-null and the queue is non-empty, the flush operation MUST remove every currently-queued alert from the queue before attempting delivery, not after a successful response.
- **flush-single-batched-post**: The flush operation MUST deliver every alert drained in one call as exactly one HTTP POST to the destination, never one request per alert.
- **flush-request-shape**: The POST MUST set header `Content-Type: application/json` and a JSON body with exactly three top-level keys: `text` (the drained alerts' rendered lines, joined; see Rendering), `content` (the identical string as `text`), and `alerts` (the drained alert list, unmodified).
- **flush-timeout-5000ms**: The POST MUST carry a deadline of 5,000 milliseconds (`ALERT_TIMEOUT_MS`), enforced by aborting the request if no response arrives in time.
- **flush-fail-soft**: When the POST call fails (a network failure or the 5,000ms abort), the flush operation MUST catch the failure, log it with the message `[alerts] webhook delivery failed (<n> alerts): <error message>` (`<n>` the count of alerts in that batch), and resolve normally; it MUST NOT re-queue the already-drained alerts and MUST NOT throw or reject.
- **webhook-non-2xx-response**: The flush operation MUST post the drained batch to the webhook and log a thrown error. It does not inspect the response status: a receiver answering with a 4xx or 5xx status is treated as a successful delivery, with no log line and no retry, and the batch was already drained from the queue before the request was sent.

### Rendering

- **render-opened**: Rendering an `opened` alert MUST produce the string `🔴 opened<state>: <name><environment><detail>`, where `<state>` is a leading space plus `state` when `state` is a non-empty string (else omitted entirely), `<environment>` is ` (` + `environment` + `)` when `environment` is a non-empty string (else omitted), and `<detail>` is ` — ` + `detail` when `detail` is a non-empty string (else omitted).
- **render-retired**: Rendering a `retired` alert MUST produce `🗑 monitor removed: <name><environment><detail>`, applying the same `<environment>`/`<detail>` composition rules as render-opened, and MUST NOT include the alert's `state` field anywhere in the rendered line even when it is non-null.
- **render-resolved**: Rendering a `resolved` alert MUST produce `✅ resolved: <name><environment>`, applying the same `<environment>` composition rule as render-opened, and MUST NOT include the alert's `state` or `detail` fields anywhere in the rendered line even when they are non-null.
- **render-lines-joined**: The flush operation MUST join the drained alerts' rendered lines with a single `\n` between each, in the same order the alerts were drained (oldest queued first, after any `MAX_QUEUED` drops), to build the `text`/`content` string.

### Test Hook

- **reset-clears-queue**: The reset operation MUST synchronously empty the queue and MUST NOT perform any network call.

### Ordering and Concurrency

- **queue-is-module-singleton**: The queue MUST be a single instance shared by every call to the enqueue and flush operations that runs against the same loaded instance of this module; the module exposes no way to construct an independent queue. Within one such instance, two calls into this module MUST NOT interleave their queue mutations — this ordering is a fact of the runtime, not a race requiring a lock.
- **queue-is-per-thread-instance**: Because this module may be loaded independently by more than one isolated execution context (for example, a background worker and the process that also imports it), an alert queued in one context's instance of this module MUST NOT become visible to, or be delivered by, a call to the flush operation made from a different context's instance; whichever execution context calls the enqueue operation for a given alert MUST also be the context that calls the flush operation for that alert to ever be delivered. This is not directly observable from a single context's own use of this module, but is a structural consequence of the module's state being scoped per loaded instance — which is why this module has three independent flush call sites external to it: one flushes from the monitor's own background execution context, while the other two flush from the API-serving context specifically because an alert queued by an API-triggered ledger write would otherwise sit in that context's queue forever — the monitor context's next flush call can never see it, because it is a different instance's queue.

