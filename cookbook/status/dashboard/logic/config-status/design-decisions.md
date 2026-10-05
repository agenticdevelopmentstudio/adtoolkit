
**Decision**: The paused switch folds into the engine's single opt-out flag at the app boundary, not as a new field in the engine.
**Rationale**: The header comment says the monitoring switch "means nothing to the engine's other consumers; giving the classifier a field per host vocabulary is how a shared model stops being shared." Paused means out of the auto-configure conversation, which is exactly what the per-endpoint opt-out means.
**Approved**: pending

**Decision**: `isActive` is optional and checked with `=== false`, not by falsiness.
**Rationale**: The field comment says a caller that does not carry it "must not have `undefined` read as 'disabled' and silently lose its warning". The test "an ABSENT isActive is not read as disabled" pins it.
**Approved**: pending

**Decision**: `endpointUnconfigured` delegates to this module's wrapper rather than the engine's predicate of the same name.
**Rationale**: The engine's predicate "would classify the raw row and miss the paused fold, so the two predicates would disagree about the same endpoint."
**Approved**: pending

**Decision**: The fold is exported as `autoConfigureOptedOut`, named after the server's twin. (React/Web implementation — `autoConfigureOptedOut` is this module's own export name.)
**Rationale**: One expression of the fold serves both the classifier here and the auto-configure adapter's endpoint-projection mapping, and sharing the server function's name makes a divergence "visible as two different answers to one question rather than two unrelated helpers."
**Approved**: pending

**Decision**: A paused but wired site stays `configured`.
**Rationale**: The engine reads the opt-out only in its unwired branch, so "pausing a site does not un-configure it"; the test says downgrading it "would misreport a healthy setup" in the Config badge. Its deploy project likewise stays claimed (the backend's `listEndpointsForWiring`).
**Approved**: pending

