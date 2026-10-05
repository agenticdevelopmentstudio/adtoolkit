
**Decision**: Keep the revive-on-conflict update's guard clause — reviving only a row whose delete column is set — so that re-adding an edge, assignment, or keyword that is already live changes no columns, rather than letting the upsert unconditionally rewrite the updated-at and ordering columns on every call.
**Rationale**: An unconditional update would stage a mutation into the taxonomy outbox on every idempotent re-add, since staging follows the count of rows the database engine reports as actually changed; the guard makes "already exists and live" distinguishable from "actually changed" at the SQL level instead of requiring a pre-read.
**Approved**: pending

