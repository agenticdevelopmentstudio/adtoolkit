
**Decision**: Keep the web vocabulary as a hand-copied mirror of the server module, guarded by a parity test.
**Rationale**: The source comment says "there is no shared build between the two packages". Drift would make the board mislabel deploys silently, so `deploy-status-parity.test.ts` imports both modules and compares the in-flight constants, `isInFlight` and `combinedStatus` across all 35 phase pairs.
**Approved**: pending

**Decision**: Treat `unknown` as terminal and check it before the in-flight rules in `combinedStatus`.
**Rationale**: `unknown` marks a phase nothing could re-confirm within the expiry window. Checking it first guarantees "an expired row can never re-read as building". A real `failed` still wins, because failure is checked before it.
**Approved**: pending

**Decision**: Map Railway `CRASHED` to built and deployed, and `FAILED` to a failed build.
**Rationale**: Per the source comments, a runtime crash is a health concern, not a deploy failure. The single Railway enum cannot separate build failure from deploy failure, and build failure is the common case.
**Approved**: pending

**Decision**: Only a Vercel production deployment gets a deploy phase.
**Rationale**: For non-production targets build-ready is go-live (per the test's description), so `combinedStatus` reads `built` with `none` as `"success"`. A production build that is `STAGED` has not been promoted, so it gets no deploy entry.
**Approved**: pending

**Decision**: Unrecognized provider states fall through to `"building"` rather than an error.
**Rationale**: The Vercel comment lists `BLOCKED` and unknown values alongside `BUILDING` and `INITIALIZING`. The in-flight claim is bounded by the confirmation window in `row-model.ts` (`deployDtoUnconfirmed`), so an unexpected value demotes rather than asserting progress forever.
**Approved**: pending

**Decision**: Add `IN_FLIGHT_STATUSES` and `deployStatusInFlight` to the web copy only.
**Rationale**: Panels that render a `DeploymentDTO` directly (DeployList, the "Build pipeline" counts) see only the collapsed `status`, not the phases. They need an in-flight test over `DeployStatus` to demote a wedged build in step with the activity list, whose demotion the server applies.
**Approved**: pending

