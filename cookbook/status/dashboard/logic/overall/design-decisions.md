
**Decision**: Report all-down as `"major_outage"`, but any partial failure (some down, or any degraded) as `"degraded"`.
**Rationale**: `computeOverall` tests `every(... "down")` before `some(... "down" || "degraded")`, so a full outage is kept distinct from a partial one; a single down service among healthy ones reads as degraded, not outage.
**Approved**: pending

**Decision**: Return `"unknown"` for an empty array instead of `"operational"`.
**Rationale**: The first check in `computeOverall` is `statuses.length === 0`; with no services reporting, the rollup refuses to claim everything is fine.
**Approved**: pending

**Decision**: Keep a client-side copy of the rollup and type even though the client does not call `computeOverall` at runtime.
**Rationale**: `src/types.ts` needs `OverallStatus` to type `StatusResponse.overall`; the function sits with it and is covered by `overall.test.ts`. The duplicate of the server's `monitor/overall.ts` has already drifted (the server adds `publicOverall`), which is why the client displays the server's verdict rather than recomputing it.
**Approved**: pending

