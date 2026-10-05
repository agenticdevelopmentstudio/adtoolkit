
**Decision**: A full snapshot is sent every time, never a delta.
**Rationale**: A receiver that was down for one change is corrected by the next push, which a delta would leave half-configured; the cost is a slightly larger body, which settings groups can afford.
**Approved**: pending

**Decision**: Retry is bounded, not infinite.
**Rationale**: A dropped push leaves the receiver on its last-known state until the next change re-pushes, so endless retry would only keep a stale body alive against a newer one.
**Approved**: pending

**Decision**: The reconnect handler stays registered after stop and is inert.
**Rationale**: The registrar offers no way to unregister, so one registration per instance with an observing check avoids both duplicate handlers and leaked pushes.
**Approved**: pending

