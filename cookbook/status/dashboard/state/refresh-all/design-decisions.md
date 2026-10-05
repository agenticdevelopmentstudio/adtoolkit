
**Decision**: Refresh every supporting dataset on one shared tick instead of giving each one its own refresh interval.
**Rationale**: The goal is that the dashboard never shows a mix of fresh and stale datasets — no staggered, mismatched state. The refetches start together but still finish independently.
**Approved**: pending

**Decision**: Exclude the live entry from the shared tick.
**Rationale**: The live entry drives itself through Live Snapshot's own refresh interval, which stands down while its stream is connected. Refetching it here too would double the provider fan-out to two polls per minute per client.
**Approved**: pending

**Decision**: Skip disabled reads.
**Rationale**: An observer that opted out of fetching should not have that gate undone every 60 s. Because the disabled test is false while any observer is enabled, a role-gated caller relies on that gate being the deciding one.
**Approved**: pending

**Decision**: Select entries with a filter over the whole cache instead of a list of keys.
**Rationale**: New datasets join the shared refresh automatically with no edit to Refresh All. The trade-off is that an unobserved cached entry that has fetched before is also refetched until it leaves its retention window.
**Approved**: pending

**Decision**: Make `refreshAll` fire-and-forget.
**Rationale**: Results and errors belong to each entry's observers. The aggregate result carries no useful signal, and discarding it satisfies a no-floating-result lint rule on the source platform.
**Approved**: pending

