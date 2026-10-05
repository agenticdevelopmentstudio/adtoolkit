
**Decision**: Response History polls every 60 seconds with a hard-coded refresh interval.

**Rationale**: The overview graph is a live portfolio summary; the source fixes the period at `60_000` ms rather than taking it from the caller, so every window length refreshes at the same rate.

**Approved**: pending

---

**Decision**: Response History fetches through the client's raw fetch operation and checks the response's `ok` flag itself, instead of using the client's JSON-decoding helper.

**Rationale**: The source chooses the raw method and raises its own short `response-history <status>` error message. As a result it drops the server's error detail and treats a 204 as a parse failure; both follow from that choice, and it matches the sibling History concept.

**Approved**: pending

---

**Decision**: Response History sends only `hours` and leaves the bucket count to the backend.

**Rationale**: The backend route accepts `hours` and `buckets`, but Response History sends no `buckets`, so the series length is a backend decision and the consumer draws whatever length arrives.

**Approved**: pending

---

**Decision**: `hours` is passed through without validation.

**Rationale**: The parameter is numeric and its only caller supplies fixed constants (24, 168, 720, 2160). Rejecting out-of-range values is left to the backend route.

**Approved**: pending

