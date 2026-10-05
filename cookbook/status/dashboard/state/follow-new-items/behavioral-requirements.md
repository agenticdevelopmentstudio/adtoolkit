
### The at-edge predicate

- **at-edge-signature**: The at-edge predicate MUST take a geometry snapshot with numeric content size, viewport size and scroll offset, an `edge` of `"top"` or `"bottom"`, and an optional `slack` in pixels, and MUST return a boolean.
- **at-edge-default-slack**: When `slack` is omitted, the predicate MUST use `PIN_SLACK_PX`, which is 24.
- **at-edge-bottom**: For `edge === "bottom"`, the predicate MUST return true exactly when `contentSize - viewportSize - scrollOffset <= slack`.
- **at-edge-top**: For `edge === "top"`, the predicate MUST return true exactly when `scrollOffset <= slack`.
- **at-edge-inclusive**: The slack comparison MUST be inclusive: a distance equal to `slack` counts as at the edge.
- **at-edge-purity**: The predicate MUST read only its arguments and MUST NOT touch the container or any other state.

### Behavior contract

- **hook-signature**: Follow New Items MUST accept a reference to the scroll container (or none), an `edge` of `"top"` or `"bottom"`, a `newestKey` (a string or none), an optional `oldestKey` (a string or none, defaulting to none) and an optional numeric `count` (defaulting to `0`).
- **hook-return**: Follow New Items MUST produce no return value; its only observable output is the container's scroll offset.
- **edge-meaning**: `edge` MUST name the edge at which the caller renders the NEWEST row: `"bottom"` for oldest-to-newest (chat-log) order, `"top"` for newest-first order.
- **head-key**: Follow New Items MUST treat `newestKey` as the key of the row at the top of the list when `edge` is `"top"`, and `oldestKey` as that key when `edge` is `"bottom"` (the "head key").
- **list-change-trigger**: The list-change pass MUST run after every update in which any of the container reference, `edge`, `newestKey`, `oldestKey`, the head key or `count` changed.
- **count-insert-trigger**: A change to `count` alone, with both keys unchanged, MUST trigger the list-change pass, so an insert in the middle of the list is followed.
- **null-container**: When the caller's container reference is none, both the listener setup and the list-change pass MUST do nothing.
- **row-order-precondition**: The container's direct children are the rows; per this concept's documentation the caller MUST render them stacked top-to-bottom in list order, so their bottom edges increase monotonically.

### Pinned state

- **pinned-initial**: The pinned state MUST start true on first attach, so a freshly attached list snaps to its edge on the first list-change pass.
- **pinned-on-scroll**: On every scroll change of the container, Follow New Items MUST set the pinned state to the at-edge predicate's result for that container and edge with the default 24 px slack.
- **scroll-listener-passive**: Monitoring scroll position MUST NOT interfere with or block the platform's own handling of the scroll.
- **scroll-reanchor**: On every scroll change, Follow New Items MUST re-measure the anchor.

### Anchor measurement

- **anchor-definition**: The anchor MUST be the first row in the container whose bounding box bottom is greater than the container's bounding box top, together with its offset (row top minus container top).
- **anchor-empty**: When no row satisfies that condition (no children, or no layout so every measurement is zero), the anchor MUST be none.
- **anchor-binary-search**: The anchor search MUST find the partition point by binary search over the rows, reading a logarithmic number of measurements, and MUST NOT write layout between reads.

### List-change pass

- **pass-timing**: The list-change pass MUST run synchronously after the rendered rows update and before the next paint.
- **repin-when-pinned**: While pinned, the pass MUST set the scroll offset to `contentSize` for `edge === "bottom"` and to `0` for `edge === "top"`.
- **repin-wins**: While pinned, re-pinning MUST take precedence over anchoring, even when a held anchor exists.
- **anchor-compensation**: While not pinned, when the held anchor row is still present and is still a descendant of the container, the pass MUST add to the scroll offset the anchor row's current offset from the container's top minus its recorded offset.
- **anchor-zero-shift**: When that shift is exactly 0, the pass MUST NOT write the scroll offset.
- **anchor-capped-list**: Anchor compensation MUST hold the reader's row even when a row arriving at the top is matched by a row leaving the bottom, so the container's total content size does not change.
- **fallback-growth**: While not pinned and with no usable anchor, the pass MUST add `contentSize - previousContentSize` to the scroll offset only when the head key is non-none, a previous head key has been recorded, and the head key differs from the previous one.
- **fallback-far-end**: When only the far-end key changes (the key that is not the head key), the fallback MUST NOT move the scroll offset.
- **fallback-first-pass**: On the first list-change pass after attach no previous head key exists, so the fallback MUST NOT fire.
- **pass-bookkeeping**: At the end of every pass that has a container, Follow New Items MUST record the current head key and content size as the previous values.
- **pass-reanchor**: At the end of every pass that has a container, Follow New Items MUST re-measure the anchor.

### Resize handling

- **resize-observer**: When resize notifications are available in the runtime, Follow New Items MUST observe the container for size changes.
- **resize-repin**: On a container resize while pinned, Follow New Items MUST set the scroll offset to `contentSize` for `"bottom"` or `0` for `"top"`.
- **resize-leave-unpinned**: On a container resize while not pinned, Follow New Items MUST NOT change the scroll offset.
- **resize-reanchor**: On every container resize, Follow New Items MUST re-measure the anchor.
- **resize-absent**: When resize notifications are unavailable, Follow New Items MUST skip resize handling and MUST NOT throw.

### Lifecycle and ordering

- **listener-deps**: The scroll listener and resize observation MUST be (re)attached whenever the container reference, `edge` or `count` changes, so the listeners attach once a conditionally rendered container appears.
- **listener-cleanup**: Before re-attaching and when the behavior is removed, Follow New Items MUST remove the scroll listener and disconnect the resize observation.
- **single-thread**: All reads and writes MUST happen on a single execution thread; scroll changes, resize notifications and the list-change pass cannot interleave, so their ordering is the order the runtime dispatches them.
- **no-persistence**: Follow New Items MUST keep pinned state, anchor, previous head key and previous content size in memory for the behavior's lifetime only, and MUST NOT persist any of them.
- **no-network**: Follow New Items MUST NOT perform network, storage, logging or timer side effects.
- **client-only**: Follow New Items MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

