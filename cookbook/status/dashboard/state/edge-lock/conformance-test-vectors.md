
Vectors 001–008 come from the reference implementation's test assertions, using a mock resize observer and an element whose scroll offset is clamped to `[0, contentSize - viewportSize]`. Vectors 009–012 are traced to the source directly.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| edge-lock-001 | fresh-element-pin, pin-bottom | Element with `contentSize` 1000 and `viewportSize` 400; mount with `edge` `"bottom"`, `newestKey` `"newest"`, `count` 3 | Scroll offset is 600 |
| edge-lock-002 | resize-bottom-restores-dist, resize-unconditional | 001 mounted (dist 0); `viewportSize` set to 300; resize reported | Scroll offset is 700 |
| edge-lock-003 | pure-scroll-records-dist, resize-bottom-restores-dist, resize-resync | 001 mounted; user scrolls to 100 (dist 500); `viewportSize` set to 300 and resize reported; then `viewportSize` set back to 400 and resize reported | Scroll offset is 200 after the first resize and 100 after the second |
| edge-lock-004 | item-follow-within-slack | 001 mounted with `newestKey` `"a"`; user scrolls to 580 (dist 20); `contentSize` set to 1100; update with `newestKey` `"b"`, `count` 4 | Scroll offset is 700 |
| edge-lock-005 | item-leave-reader-put | 001 mounted; user scrolls to 100 (dist 500); `contentSize` set to 1100; update with `newestKey` `"b"`, `count` 4 | Scroll offset stays 100 |
| edge-lock-006 | no-prepend-compensation, item-leave-reader-put | Mounted with `newestKey` `"z"`, `count` 9; user scrolls to 100; `contentSize` set to 700; update with `newestKey` `"y"`, `count` 4 | Scroll offset stays 100 |
| edge-lock-007 | geometry-changed-scroll-keeps-dist, pure-scroll-records-dist, item-signal | 001 mounted (scroll offset 600); `contentSize` set to 1100 with no scroll change reported; user scrolls to 500, then to 200 (dist 500); `contentSize` set to 1200; update with `newestKey` `"b"`, `count` 4 | Scroll offset stays 200 |
| edge-lock-008 | attach-replace, attach-null-element, fresh-element-pin | Mounted on element A (1000/400); user scrolls A to 100; container reference set to none and updated; container reference set to new element B (800/400) and updated | B's scroll offset is 400 |
| edge-lock-009 | pin-top, fresh-element-pin | Element with scroll offset 300; mount with `edge` `"top"` | Scroll offset is 0; tracked `dist` is 0 |
| edge-lock-010 | resize-top-no-write, resize-resync | `edge` `"top"`, user scrolled to 150; resize reported | The behavior does not write the scroll offset; tracked `dist` equals the platform's scroll offset (150 unless the platform clamped it) |
| edge-lock-011 | resize-observer-absent | Resize notifications unavailable; mount a bottom-locked element (1000/400) | Scroll offset is 600; no observer is created; a later resize changes nothing |
| edge-lock-012 | item-follow-within-slack | Bottom edge, dist exactly 24; update with a new `count` after `contentSize` grows by 100 | The element is pinned to the tail (24 is inside the slack, since the comparison is `<=`) |
| edge-lock-013 | client-only | Load Edge Lock in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

