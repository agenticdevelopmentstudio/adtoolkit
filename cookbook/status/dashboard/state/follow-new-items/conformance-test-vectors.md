
Vectors 001–008 exercise the at-edge predicate; 009–020 exercise the full behavior (a mock element with fixed sizes for the fallback path; modelled 100 px rows in a 400 px viewport for the anchored path).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| follow-001 | at-edge-bottom, at-edge-inclusive | Content size 1000, viewport size 400, scroll offset 600, edge `"bottom"` | `true` |
| follow-002 | at-edge-bottom, at-edge-default-slack | Content size 1000, viewport size 400, scroll offset 580, edge `"bottom"` | `true` (20 px within 24) |
| follow-003 | at-edge-bottom | Content size 1000, viewport size 400, scroll offset 560, edge `"bottom"` | `false` (40 px away) |
| follow-004 | at-edge-top | Scroll offset 0, then 20, then 40, edge `"top"` | `true`, `true`, `false` |
| follow-005 | at-edge-bottom, at-edge-top | Content size 400, viewport size 400, scroll offset 0, checked for both edges | `true` for both |
| follow-006 | at-edge-signature, at-edge-inclusive | Content size 1000, viewport size 400, scroll offset 560, edge `"bottom"`, slack 40 | `true` |
| follow-007 | at-edge-signature | Content size 1000, viewport size 400, scroll offset 559, edge `"bottom"`, slack 40 | `false` |
| follow-008 | at-edge-purity | Evaluate the predicate against a plain geometry snapshot with no live container | Returns a boolean; no container access |
| follow-009 | pinned-initial, repin-when-pinned | Attach with `edge "bottom"`, element 1000/400 | Scroll offset is 1000 |
| follow-010 | resize-repin | After 009, set scroll offset to 600 with no scroll change reported, then resize | Scroll offset is 1000 |
| follow-011 | pinned-on-scroll, resize-leave-unpinned | Attach `"bottom"`, set scroll offset 100, report scroll, then resize | Scroll offset stays 100 |
| follow-012 | pinned-initial, resize-repin | Attach with `edge "top"`; then set scroll offset 600 and resize | 0 after attach; 0 after resize |
| follow-013 | repin-when-pinned, head-key | `"top"`, scroll offset 10 plus a scroll report (within slack), update `newest "a"` to `"b"`, `count` 3 to 4 | Scroll offset is 0 |
| follow-014 | fallback-growth | `"top"`, no children, scroll offset 500 plus a scroll report, content size 1000 to 1200, update `newest "a"` to `"b"` | Scroll offset is 700 |
| follow-015 | fallback-far-end | `"top"`, no children, scroll offset 500 plus a scroll report, content size 1000 to 1200, update `oldest "z"` to `"y"` | Scroll offset stays 500 |
| follow-016 | anchor-compensation, anchor-capped-list | 10 rows, `"top"`, scroll offset 500 plus a scroll report (reader on k5); prepend a row and remove the last (content size stays 1000); update `newest "new"`, `count` 10 | Scroll offset is 600; reader still on k5 |
| follow-017 | anchor-compensation | Same as 016 without removing a row; update `count` 11 | Scroll offset is 600; reader on k5 |
| follow-018 | anchor-zero-shift | 10 rows, `"top"`, scroll offset 500 plus a scroll report; append a row at the bottom; update `count` 11 | Scroll offset stays 500; reader on k5 |
| follow-019 | repin-wins | 10 rows, `"top"`, scroll offset 10 plus a scroll report; prepend a row and remove the last; update | Scroll offset is 0; reader on the new row |
| follow-020 | null-container | Attach with the container reference as none | No error; no listener attached; nothing written |
| follow-021 | resize-absent | Attach with resize notifications unavailable, element 1000/400 `"bottom"` | Attach still sets scroll offset 1000; no throw |
| follow-022 | fallback-first-pass, pass-bookkeeping | `"top"`, no children, `newest "a"`, content size 1000; after attach report a scroll at offset 500, then update with the same keys and `count` | Scroll offset stays 500: the head key equals the one recorded on the first pass, so no growth is added |
| follow-023 | count-insert-trigger | Pinned `"bottom"`, update with same keys and `count` 3 to 4 after content size grows to 1200 | Scroll offset is 1200 |
| follow-024 | listener-cleanup | Remove the behavior | Scroll listener removed; resize observation disconnected; later scroll reports do not change pinned state |
| follow-025 | client-only | Load Follow New Items in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

