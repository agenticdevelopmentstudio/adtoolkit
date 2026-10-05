
**Decision**: Mark `lastCycleAt`, `probeIntervalMs` and `monitorVersion` optional on the client although the server copy declares them required.
**Rationale**: The doc comments say each is optional "so an older backend degrades" to no warning, the client's floor, or no version shown; the client must tolerate backends that predate the fields.
**Approved**: pending

**Decision**: Carry `downSince` as server truth rather than the client's per-tab onset.
**Rationale**: The doc comment calls it "durable across browsers (unlike the client store's per-tab onset)"; the retire-stale-monitor surface judges a 7-day outage and needs an onset that survives reloads.
**Approved**: pending

**Decision**: Carry `lastCycleAt` separately from `generatedAt`.
**Rationale**: `generatedAt` "is read-time and always looks fresh", so only the newest-persisted-probe clock can expose a wedged or never-redeployed poller.
**Approved**: pending

**Decision**: Keep the module type-only with no DB imports.
**Rationale**: The header states it is shared by the route and the client store; a DB import would drag server code into the browser bundle.
**Approved**: pending

