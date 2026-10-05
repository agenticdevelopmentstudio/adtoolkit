
**Decision**: Compensate a scrolled-away reader by the anchored row's own shift, not by the container's total content-size growth.

**Rationale**: Activity is server-capped at `MAX_ACTIVITY_ROWS`, so on a full list each row arriving at the top drops one off the bottom; the total delta then reads about 0 while a whole row was inserted above the reader, sliding them up by a row every update.

**Approved**: pending

---

**Decision**: Keep a measurement-free fallback (total content-size growth, gated on the head key changing).

**Rationale**: When the reader's row has left the list, or the environment does no layout, there is no row to measure; total growth is correct whenever nothing left the far end, and the head-key gate stops growth at the far end from moving anyone.

**Approved**: pending

---

**Decision**: Choose the head key from `edge` rather than always watching `oldestKey`.

**Rationale**: Only growth at the top of the list moves a scrolled-away reader; for a newest-first list the top row is the newest, so hard-coding `oldestKey` watched the bottom row, whose growth needs no compensation.

**Approved**: pending

---

**Decision**: Re-run on `count` as well as the end keys.

**Rationale**: An insert in the middle (a completed deploy next to an in-flight build) changes neither end; `count` changing is what makes the tail follow it, and it also re-attaches listeners once a conditionally rendered container appears, since a reference alone does not re-trigger effects.

**Approved**: pending

---

**Decision**: Find the anchor by binary search.

**Rationale**: With history pages loaded above the live page, the row count is unbounded; a linear scan cost thousands of forced-layout reads per scroll event, while the rows' monotonic bottoms make the first row past the top a partition point found in a logarithmic number of reads from one layout.

**Approved**: pending

---

**Decision**: Re-pin on container resize while pinned, using resize notifications.

**Rationale**: Dragging a surrounding split changes the viewport without changing the rendered list, so the list-change pass never runs and the platform leaves the scroll offset put, sliding the tail rows out of view.

**Approved**: pending

---

**Decision**: A 24 px slack (`PIN_SLACK_PX`) counts as pinned.

**Rationale**: Small nudges (a filter click, a keyboard-driven scroll-into-view) move the viewport a few pixels; within the slack the list keeps tailing, and only a deliberate scroll further away leaves the reader in place.

**Approved**: pending

