
**Decision**: Hand-mirror the server's board types instead of importing them.
**Rationale**: The header comment states the web app "cannot import at runtime" the server tree; there is no shared package between the backend and its embedded web app. Drift is caught by the parity test's `Exact<A, B>` checks, compiled by two typechecks.
**Approved**: pending

**Decision**: Carry `tone` and `verb` on the wire instead of deriving them in the client.
**Rationale**: "the server owns what a row SAYS, exactly as it owns whether the row exists"; `ActivityTone` matches `RowTone` one-for-one so the pane renders it directly, and `kind` is never recomputed from `tone` (the doc comment cites that exact mistake as defect #1 in the spec).
**Approved**: pending

**Decision**: Platform-health targets use two segments, `platform-health|<source>`, not `boardTargetKey()` output.
**Rationale**: That spelling already exists in the `issues` table; "a provider is not a deploy target, and giving it a third segment would orphan every live platform-health row for no gain."
**Approved**: pending

**Decision**: Deploy row ids exclude target and timestamp.
**Rationale**: Those deployment fields are corrected after first render, and the client cannot distinguish a renamed row from a replaced one, so ids must use only immutable components.
**Approved**: pending

**Decision**: Paging cursor is the `(atMs, id)` pair.
**Rationale**: Build and deploy rows of one deployment share a `createdAtMs`; a time-only cursor would re-serve or skip one of them.
**Approved**: pending

**Decision**: `Board` carries `probeIntervalMs`, `activityFromMs` and `monitoredTargets`.
**Rationale**: The cadence previously arrived only on the SSE stream and was null for non-stream consumers; the activity boundary is read rather than re-derived; `monitoredTargets` replaces `/live`'s `deployTargets` so the ledger writer can tell recovery from de-configuration, since `resolveIssue` alerts on the first and stays silent on the second.
**Approved**: pending

