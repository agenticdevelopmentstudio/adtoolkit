
### Signature and data shape

- **signature**: Edge Lock MUST be callable with four inputs: a reference to a scroll container element (or none), `edge` (`"top" | "bottom"`), `newestKey` (a string or none), and `count` (a number that defaults to `0`). It MUST produce no return value.
- **tracked-record**: The behavior MUST keep one mutable tracked-geometry record per instance with the fields `element`, `contentSize` (the container's total scrollable size), `viewportSize` (the container's visible size), and `dist` (distance from the locked edge). The record MUST start as `{ element: none, contentSize: 0, viewportSize: 0, dist: 0 }`.
- **dist-bottom**: When `edge` is `"bottom"`, the measurement step MUST compute `dist` as `contentSize - viewportSize - scrollOffset`.
- **dist-top**: When `edge` is `"top"`, the measurement step MUST compute `dist` as `scrollOffset`.
- **pin-bottom**: When `edge` is `"bottom"`, the pin operation MUST set the scroll offset to `max(0, contentSize - viewportSize)`.
- **pin-top**: When `edge` is `"top"`, the pin operation MUST set the scroll offset to `0`.
- **no-rendered-output**: The behavior MUST NOT hold state that triggers a screen update on change; all of its bookkeeping lives in internally-held mutable fields (the tracked record and the current detach operation).

### Attaching to the scroll element

- **attach-per-render-check**: The attach step MUST re-check its target on every update, not only when specific inputs change.
- **attach-identity-guard**: The attach step MUST return early without re-wiring when the caller's current container element is the one already stored in the tracked record's `element` field and a detach operation exists.
- **attach-replace**: When the caller's current container element differs from the tracked element, the attach step MUST first run the previous detach operation (if any), which removes the old scroll listener and disconnects the old resize observer.
- **attach-null-element**: When the caller's current container element is none, the attach step MUST reset the tracked record to `{ element: none, contentSize: 0, viewportSize: 0, dist: 0 }` and attach nothing.
- **scroll-listener-passive**: The behavior MUST monitor scroll-position changes on the element without interfering with or blocking the platform's own handling of the scroll.
- **fresh-element-pin**: Once monitoring is attached to a new element, the behavior MUST pin that element to its edge with the pin operation and then set the tracked record from a fresh measurement. This rests a fresh list on its edge and throws away any distance measured on a previous element.
- **unmount-teardown**: A separate teardown step MUST run the detach operation exactly once, when the behavior is removed, and clear it. The attach step itself performs no cleanup on each run, so nothing is torn down while the behavior remains active.

### Scroll tracking

- **pure-scroll-records-dist**: When a scroll change is reported and the element's `contentSize` and `viewportSize` both equal the tracked values, the behavior MUST replace the tracked record with a fresh measurement, which records the user's new `dist`.
- **geometry-changed-scroll-keeps-dist**: When a scroll change is reported and either `contentSize` or `viewportSize` differs from the tracked values, the behavior MUST adopt the new `contentSize` and `viewportSize` but keep the previously tracked `dist`.

### Resize lock

- **resize-observer-attach**: When resize notifications are available in the runtime, the behavior MUST subscribe to them for the scroll element.
- **resize-bottom-restores-dist**: On a resize notification with `edge` `"bottom"`, the behavior MUST set the scroll offset to `max(0, contentSize - viewportSize - tracked dist)`.
- **resize-top-no-write**: On a resize notification with `edge` `"top"`, the behavior MUST NOT write the scroll offset.
- **resize-resync**: After every resize notification, the behavior MUST set the tracked record from a fresh measurement, so the tracked `dist` matches the position the platform actually allowed, including any clamping.
- **resize-unconditional**: The resize lock MUST apply whatever the current `dist` is. It has no slack threshold and no "only while pinned" condition.
- **resize-observer-absent**: When resize notifications are unavailable, the behavior MUST still attach the scroll listener and do the fresh-element pin, and MUST skip the resize lock.

### Item-change follow

- **item-effect-timing**: The item-change handler MUST run synchronously after the container updates for that change and before the next paint, whenever the container reference, `edge`, `newestKey` or `count` changes.
- **item-effect-identity-guard**: The item-change handler MUST do nothing when the caller's current container element is none or is not the element stored in the tracked record.
- **item-follow-within-slack**: When the tracked `dist` is less than or equal to `PIN_SLACK_PX` (24), the item-change handler MUST run the pin operation.
- **item-leave-reader-put**: When the tracked `dist` is greater than 24, the item-change handler MUST NOT change the scroll offset.
- **item-resync**: After every item-change handler run that passes the identity guard, the behavior MUST set the tracked record from a fresh measurement.
- **no-prepend-compensation**: The behavior MUST NOT shift the scroll offset to make up for content inserted above the visible area. This concept's guidance notes there is "no prepend compensation" because the sole consumer is a fixed-window store, and a scroll delta applied to a filtered-list swap corrupted the reader's place.

### Ordering and concurrency

- **main-thread-only**: Every read and write happens on a single execution thread, inside the behavior's own callbacks. Operations therefore never interleave, and the behavior MUST NOT need locking.
- **mount-order**: On the update where an element first appears, the item-change handler runs before the attach step. The item-change handler MUST skip, because the element is not tracked yet, and the attach step MUST then pin the element.
- **edge-change-while-mounted**: `edge` is effectively fixed for the life of an element. The scroll and resize monitoring capture `edge` when they are wired and are re-wired only when the element identity changes, while the item-change handler reads the current `edge`; if a caller changes `edge` while the same element stays mounted, the scroll and resize handling keep measuring `dist` from the old edge. No consumer in the reference implementation uses Edge Lock outside its test, and none toggles `edge`. A port that needs a switchable edge re-wires the handlers when `edge` changes.

### Caller preconditions

- **css-bottom-anchor**: For a bottom-locked list, the caller MUST anchor short content to the bottom in layout (a flex column, with the row block pushed to the end). This concept's guidance states this as the layout contract, because no scroll position can close the gap an underfull list leaves above the container's bottom edge.
- **item-signal**: To trigger item-change follow, the caller MUST change `newestKey` or `count`. A height change with neither of these and no container resize MUST NOT trigger a pin.
- **client-only**: Edge Lock MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

