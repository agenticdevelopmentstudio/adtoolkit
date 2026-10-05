
- **Decision**: return `"down"` from the health-kind JSON check before ever evaluating `bodyMarkerMissing`, rather than evaluating both independently and combining the results.
  **Rationale**: not stated in an inline comment; recorded here as a fact of the code per this recipe's authoring rules. The two checks happen to agree whenever both would fire (status-server-monitor-health-013), so the ordering is not currently observable in practice, but it is the exact sequence a future port MUST reproduce to stay behaviorally identical if the two checks are ever changed to disagree.
  **Approved**: pending
- **Decision**: on a JSON parse failure or a parsed body with no `status` field, fall through to the marker/latency checks rather than treating either case as `"down"` or as `"healthy"`.
  **Rationale**: stated directly in the source's own comment on the `catch` branch — "Non-JSON body (e.g. HTML page) — fall through to the marker/latency checks." A non-JSON or status-less body is not itself evidence of an outage; the marker and latency checks remain the deciding signal.
  **Approved**: pending
- **Decision**: let `bodyMarkerMissing` force `"down"` unconditionally, overriding what would otherwise be a `"healthy"` or `"degraded"` latency-based verdict.
  **Rationale**: stated directly in the source's own comment above the check — "A success status serving the WRONG content (broken shell, takeover page, empty app) is an outage the status code can't see — the marker can." A fast, well-formed-looking response serving the wrong page is still an outage regardless of how quickly it answered.
  **Approved**: pending
- **Decision**: use a strict `>` rather than `>=` for the degraded-latency comparison, so a response exactly at `DEGRADED_THRESHOLD_MS` classifies as `"healthy"`.
  **Rationale**: not stated in an inline comment; recorded here as a fact of the code per this recipe's authoring rules (degraded-latency-threshold, status-server-monitor-health-012).
  **Approved**: pending

