
- **No cache, source failing**: The state MUST return the empty snapshot indefinitely, with no error exposed; consumers render a healthy/empty state (MUST, as implemented; see the open question on telemetry-failure-signal).
- **Corrupt stored value**: Invalid JSON, a wrong-shape object, or a JSON `null` under `adh-telemetry-v1` MUST load as `null`, so the state falls back to the empty snapshot until the source answers (MUST).
- **Stored arrays with malformed elements**: Parsing checks only that `errors` and `analytics` are arrays; malformed elements pass through to consumers unchanged (MUST, as implemented).
- **Malformed 2xx body from the source**: The body is cast, not validated; a body missing `errors` returns an object whose `errors` is `undefined`, which consumers that iterate over `errors` throw on during render. The same body is saved to the cache, but parsing rejects it on the next load, so a reload recovers to empty. The body shape is owned by the backend `/telemetry` route (MUST, as implemented).
- **Non-JSON 2xx body**: Parsing the body as JSON rejects, the read retries once, then enters its error state; the state falls back to data, cache or empty per precedence (MUST).
- **Storage unavailable** (private mode, disabled storage, quota): loading returns `null` and saving is a silent no-op; the state still returns live data (MUST).
- **Server render**: No post-mount step runs, so the state returns the empty snapshot unless the read already has data from the server render; the cache adapter also guards against a missing storage environment (MUST).
- **Source outage after a success in the same session**: the platform retains the last data, so the state returns that live snapshot, not the cached one; the cache only covers the gap before the first success in a session (for example after a reload) (MUST).
- **Hidden tab**: The 60-second poll pauses while the document is hidden and a focus event triggers a refetch on return (MUST, via the platform's defaults).
- **Concurrent callers**: Concurrent mounts share one read via deduplication, and each instance's cache writes store the same value, so there is no interleaving to order (MUST).
- **Unreachable server or network timeout**: The transport rejects (or hangs until the platform's network stack gives up); the state adds no timeout, the read retries once, and the fallback precedence applies (MUST).
- **Unmount mid-fetch**: The request is not aborted; any result lands in the shared cache for other observers (MUST, as implemented).

