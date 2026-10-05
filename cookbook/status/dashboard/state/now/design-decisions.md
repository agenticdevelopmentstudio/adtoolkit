
**Decision**: Snapshot the clock into state instead of reading it directly during rendering.
**Rationale**: Reading the wall clock in-render is impure, makes "time ago" labels jump on unrelated re-renders, and is flagged by common state-hook lint rules; a stored snapshot keeps evaluation pure and stable between ticks.
**Approved**: pending

**Decision**: Coarse 30-second default refresh.
**Rationale**: The consumers show relative times and staleness judged in minutes, so a 30 s tick keeps labels current while limiting update frequency; callers may pass a smaller value when finer resolution matters.
**Approved**: pending

**Decision**: One timer per use, with no shared ticker.
**Rationale**: Keeps Now self-contained; the cost is that separate callers drift by up to one interval and each holds its own timer (`instance-independence`).
**Approved**: pending

**Decision**: No reconciliation of the server-rendered and client initial timestamps.
**Rationale**: The source relies on the lazy initializer alone; any text derived from the value can differ between server output and first client render. This rationale applies to the web platform, where a server-rendering pass and a client paint can disagree; a platform with no such split has no counterpart. Consumers accept this; a port that renders server-side should decide whether to defer the first reading to the client.
**Approved**: pending

