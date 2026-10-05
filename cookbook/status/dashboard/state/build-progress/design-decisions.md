
**Decision**: In-flight is decided only by the server's `tone === "progress"`; the former client-side 10-minute `UNCONFIRMED_AFTER_MS` clock was removed.

**Rationale**: The private clock made the progress bar read complete while the row below it still said "building" — one fact with two derivations. The server now owns demotion (`reconcile-stuck-deploys` → `"stale"`), so the bar and the row always agree; the accepted cost is that a wedged build keeps the bar visible below 100% until the server expires it.

**Approved**: pending

---

**Decision**: The cohort accumulates in state via an effect rather than being derived from the current snapshot.

**Rationale**: Completed builds leave the in-flight set, so a snapshot alone cannot know how many builds the cohort had; the ids must be remembered across snapshots. The source comments call this an external-observation sync, mirroring `useEnvFilter`'s hydration pattern.

**Approved**: pending

---

**Decision**: Hold at 100% for 2000 ms before resetting, and let a new build cancel the reset.

**Rationale**: The hold lets the viewer see completion before the bar hides; cancelling on a new build keeps a busy period in one cohort rather than flashing the bar to zero.

**Approved**: pending

---

**Decision**: A build that drops out of the feed counts as completed.

**Rationale**: The source treats "no longer asserted in flight by the board" as done, whether settled, expired or gone, because the server decides what the feed contains.

**Approved**: pending

