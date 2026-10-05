
- **Null/empty input**: an empty `localResourceRoots` array on the request MUST be passed through as-is and MUST grant the resulting panel no local resource access; this is not an error condition (MUST).
- **Repeated calls**: `dispose()` called a second time on an already-disposed panel MUST be a no-op — it MUST NOT remove the pane a second time and MUST NOT fire `onDidDispose` again, per **panel-dispose-idempotent** (MUST).
- **Repeated calls**: calling `presentWebviewPanel(_:)` twice with requests carrying the same `viewType` and `title` MUST create two independent panels; this protocol performs no identity de-duplication of its own (MUST).
- **No placement available**: presenting a webview panel when there is nowhere to place a panel (no project window open) MUST return nothing and MUST NOT reveal, wire, or otherwise partially construct a panel that is then discarded, per **presenter-nil-on-no-placement** and **presenter-failed-placement-reveals-nothing** (MUST).
- **Post after disposal**: calling `post(message:)` on a disposed panel MUST return `false` rather than throwing or silently discarding the message, per **panel-post-message-result** (MUST).
- **Stale handle re-use**: a caller holding a panel handle across a user-initiated close MUST observe `isDisposed == true` before the handle is used for a hand-over (restore or `resolveWebviewView`), which is the exact guard the resolving bridge performs, per **panel-disposed-flag** (MUST).
- **Concurrent access**: because both the presenting role and the panel handle are confined to a single thread, no method of either can be called concurrently with another from a different thread — the platform's own concurrency enforcement handles this rather than either needing its own locking (MUST).

