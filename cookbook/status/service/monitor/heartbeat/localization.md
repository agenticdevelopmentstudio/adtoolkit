
None of this file's user-facing strings route through a localization mechanism; both `console.error` messages are hardcoded English literals interpolated directly in `pingHeartbeat`. Per this recipe's authoring rules, a hardcoded string is a fact to record, not a gap to excuse — and because these are operator-facing diagnostic lines (surfaced wherever the container's stderr is collected), they are genuinely user-facing, not internal-only.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `[heartbeat] check-in URL answered <status> — the dead-man ping is NOT registering; verify HEARTBEAT_URL` | `console.error` when the response's `ok` flag is `false` |
| n/a | `[heartbeat] ping failed: <message>` | `console.error` when the `fetch` call rejects (network failure or timeout) |

