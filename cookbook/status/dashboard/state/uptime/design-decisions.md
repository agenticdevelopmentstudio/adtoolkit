
**Decision**: The hook does not poll.

**Rationale**: Unlike `useResponseHistory` (60-second `refetchInterval`), `useUptime` sets no interval. Daily uptime over 90 days changes slowly, and the source relies only on React Query's default refetch triggers.

**Approved**: pending

---

**Decision**: The hook fetches through `api.fetch` and checks `ok` itself instead of calling `api.json`.

**Rationale**: The source chooses the raw method and throws its own short `uptime <status>` message. As a result it drops the server's error detail and treats a 204 as a parse failure; both follow from that choice, and it matches the sibling `useResponseHistory` hook.

**Approved**: pending

---

**Decision**: `days` defaults to 90 and is passed through without validation.

**Rationale**: The parameter is typed `number` with a default of `90`, matching the backend route's own default, and both callers pass `90`. Bounding the value (1–365) is owned by the backend `/uptime` route.

**Approved**: pending

