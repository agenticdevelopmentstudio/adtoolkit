
- **No container element at mount**: If the caller's container reference is none, the behavior MUST attach nothing, MUST keep the tracked record at its zero values, and the item-change handler MUST do nothing. Nothing is thrown.
- **Element swapped for an empty-state node and back**: Detaching when the element becomes none, then wiring the new element and pinning it, MUST rest the new element on its own edge without carrying over the old distance (edge-lock-008).
- **Underfull list, bottom edge**: When `contentSize <= viewportSize`, the pin operation MUST set the scroll offset to 0 (the zero floor). Any visual bottom alignment is the caller's layout job (css-bottom-anchor).
- **Resize grows past the remaining scroll range**: When restoring `dist` asks for a negative scroll offset, the behavior MUST write 0 and then re-measure. The smaller `dist` the platform allowed becomes the value the next resize restores.
- **Content grows in place with no scroll or resize**: The tracked geometry goes stale until the next scroll change. That change MUST adopt the new geometry and keep `dist` (geometry-changed-scroll-keeps-dist), so later scrolls are recorded again (edge-lock-007).
- **Platform clamps scroll during a resize**: A scroll change caused by a clamp arrives with changed geometry. It MUST NOT overwrite `dist`. The resize notification re-asserts `dist`.
- **Slack boundary**: `dist` of 24 MUST follow new items. `dist` of 25 MUST NOT.
- **Negative dist**: If the scroll offset goes past its valid range, `dist` can come out negative. That is still `<= 24`, so the list follows. The behavior does not clamp `dist`.
- **Frequent `count` ticks (poll/stream)**: An update that only changes `count` MUST cost one identity check in the attach step (no re-wiring). It MUST run the item-change handler once.
- **Resize notifications unavailable (older runtime, server-side rendering)**: The resize lock is skipped entirely (resize-observer-absent). Scroll tracking and item follow still work.
- **Concurrent access**: Not applicable. Everything runs on a single execution thread (main-thread-only).
- **Errors and offline**: Not applicable. The behavior does no I/O, network or storage work, and none of its geometry reads or writes throw on a valid element.
- **Cancellation and timeouts**: The behavior starts no asynchronous work, so nothing needs cancelling. Unmount teardown removes the listener and disconnects the observer (unmount-teardown).
- **`edge` changed mid-life**: The scroll and resize handling keep the old edge until the element changes; see `edge-change-while-mounted`.

