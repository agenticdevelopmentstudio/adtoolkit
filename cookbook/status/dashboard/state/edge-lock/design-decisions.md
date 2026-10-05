
**Decision**: The resize lock keeps `dist` exactly and unconditionally, with no pinned flag.
**Rationale**: This concept's guidance says this replaced an earlier "re-pin only while pinned" rule. That rule's hidden flag was cleared by any wheel notch or keyboard-nav scroll-into-view, so the lock held only some of the time.
**Approved**: pending

**Decision**: Item-change follow uses a 24 px slack (`PIN_SLACK_PX`), and the resize lock uses none.
**Rationale**: For item changes, "resting on the edge" needs some tolerance so that small nudges still tail new content. For resizes, the exact distance is the contract, so the row at the edge stays at the edge.
**Approved**: pending

**Decision**: A scroll change with changed geometry adopts the new geometry but keeps `dist`, instead of being dropped.
**Rationale**: The source comment and regression test EL-1 say that dropping these events "permanently wedged the tracker" after any content-height change with no scroll event, which let new items yank a scrolled-up reader to the bottom.
**Approved**: pending

**Decision**: The tracked record is tagged with the element it was measured on, and every new element is pinned fresh.
**Rationale**: Regression test EL-2 covers this. When a filter empties the list, the caller swaps in an empty-state node. The remounted list has to rest on its own edge, not apply the dead node's distance.
**Approved**: pending

**Decision**: The attach step (web platform: the attach effect) has no dependency array and returns early on the same element.
**Rationale**: The source comment says a poll/stream tick that only bumps `count` should cost one identity comparison, instead of rebuilding the observer, whose fresh subscription would rewrite the scroll offset for no reason.
**Approved**: pending

**Decision**: No prepend compensation.
**Rationale**: The sole consumer is a fixed-window store that never pages older history in above the reader. Applying a scroll delta on a filtered-list swap corrupted the reader's place (regression test "filtered under them").
**Approved**: pending

