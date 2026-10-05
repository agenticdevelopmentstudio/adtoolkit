
Refresh All keeps the dashboard's supporting datasets — uptime, integrations, response history and every other cached read — on one shared refresh tick, so the dashboard never shows a mix of fresh and stale datasets.

On each tick it asks the shared cache to refetch every cached read except two groups:

- **Live Snapshot's own cache entry** (any cache key starting with `"live"`). Live Snapshot drives itself on its own refresh interval; refetching it here too would double the provider fan-out to two polls per minute per client.
- **Disabled reads** (those with no enabled observer). An observer that opted out of fetching should not have that gate undone every 60 s by a shared refresh.

Refresh All returns a `refreshAll` function so a caller can trigger the same refresh on demand. Its one caller, the board shell, uses it with a 60,000 ms interval and ignores the return value beyond that function.

