
**Decision**: History is held in-memory only, with no localStorage persistence.

**Rationale**: The source applies the reasoning in `use-board.ts` unchanged: a durable client store of server-derived rows is what let a fixed problem survive in one browser tab forever. Keeping history in-memory, and dropping it whenever `enabled` goes false, avoids that hazard.

**Approved**: pending

---

**Decision**: History array is uncapped and re-sorted on every merge.

**Rationale**: The array's size is naturally bounded by the reader's reach (a page costs a scroll gesture plus a budget reset) and the 90-day server retention window, typically a few thousand rows at the far end of determined scrolls. Sorting takes milliseconds. A cap would evict rows, creating holes in the middle of the feed that the shed-absorption effect (which exists specifically to prevent holes) would then need to work around, making the cost higher than re-sorting unbounded rows.

**Approved**: pending

---

**Decision**: The shed-absorption effect captures rows only after the first `loadOlder()` call.

**Rationale**: Before paging, there is no history to hole; the live window is the only feed. Once paging starts, a row the window drops afterward falls out of both lists (it is no longer live, and history was paged from where the window's oldest row sat when the scroll began), creating a hole in the middle of the feed. Shed absorption fills this gap cheaply (the row was already transmitted in an earlier frame) without issuing a fetch.

**Approved**: pending

---

**Decision**: Shed rows with `tone: "progress"` are never captured, even if aged out.

**Rationale**: A progress row asserts ongoing work. The server's own freshness contract terminates unconfirmed in-flight phases at 6 hours (far inside the 24h floor), so a progress row aging out is already anomalous. Freezing it as a shed row would create a claim about live work that nothing will ever re-confirm.

**Approved**: pending

---

**Decision**: Failed pages do not roll back the fetch count or advance the cursor.

**Rationale**: The fetch count is a budget that controls spam; it is already spent by the time the request is made. If a page fails with a broken endpoint, rolling back the count would allow retrying that same broken endpoint infinitely via auto-continue. Keeping the cursor unchanged allows the pane to retry the same window on the next scroll without skipping it, but the budget prevents hammering.

**Approved**: pending

---

**Decision**: Timeout is hard-coded at 20 seconds per page, not configurable.

**Rationale**: A request that never settles (dropped connection, proxy holding socket, laptop suspended mid-flight) leaves `loading: true` for the life of the tab, blocking auto-continue and leaving the pane stuck with "loading older activity…". Abandoning the page after 20 seconds surfaces the ordinary error line instead, which the next scroll retries.

**Approved**: pending

---

**Decision**: Merge strategy is incoming-copy-wins, not existing-wins.

**Rationale**: Row ids are stable (`deriveActivity`'s `deployRowId`), so a corrected row arrives under the SAME id with different fields. If existing won, the correction would be silently dropped and the stale copy would remain the only account of that deployment, with no later page able to repair it because cursors only move backward. Incoming is always the more recent read of the same fact; a byte-identical row still leaves `prev` untouched.

**Approved**: pending

