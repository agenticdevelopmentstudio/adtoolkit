
**Decision**: The server is the source of truth: the backend owns the manifest, the single cohort cursor, and every push outcome, and the client mirrors and queues without fabricating a cursor, re-deriving enrollment, or overriding a push result.
**Rationale**: This is what makes the client replaceable per platform without forking the contract.
**Approved**: pending

**Decision**: A resource that appears in the effective set on a non-fresh cursor triggers a full resync (reset the mirror and cursor, then re-pull); a fresh (nil) cursor is exempt.
**Rationale**: The server keeps one cursor stream per cohort and does not bump row versions or re-serve rows when a resource is enrolled-enabled (see the backend sync architecture document), so rows that changed while the resource was outside the set sit permanently behind the cursor and an incremental pull would never see them; the initial pull already covers everything on a fresh cursor.
**Approved**: pending

**Decision**: A local op for a resource that left the effective set is quarantined, neither dropped nor pushed nor held live.
**Rationale**: It can neither be pushed (the server would reject it) nor kept live (the host must stop serving that resource); dropping it would lose the user's edit and pushing it would leak data across an enrollment boundary. A fixed retry re-stages for a fresh op id, because the server ledgers results immutably per op id.
**Approved**: pending

**Decision**: The client-side sync catalog lives in the client, not on the manifest wire.
**Rationale**: Push mode (route versus generic) and the registration list are client knowledge: the catalog lets a host register the right tables and refuse a pull-only write before a round trip. Encoding that on the pull manifest would bloat every response with data the server already enforces authoritatively (it answers a mis-push with `rejected/route_only`); the catalog is an optimization that can go stale, and the manifest and push results remain the backstop.
**Approved**: pending

