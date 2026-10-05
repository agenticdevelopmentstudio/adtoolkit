
- **Non-ok status**: Any status outside 200–299 (including 401, 404, 502) MUST fail with the status-only message; the response body is not read, so any server error detail is dropped from the message.
- **Malformed body on ok response**: Parsing the response body fails with a syntax error, which MUST propagate unchanged as the read operation's failure (and as the cached state's query error); for the cached state the latch stays armed.
- **Well-formed body of the wrong shape**: The body MUST be returned as-is with no validation (see response-cast-unvalidated); a missing `projects` array reaches consumers as undefined.
- **Missing `verifiedPlatforms`**: The field is optional; consumers MUST treat every wiring as live (verified-platforms-absent).
- **Empty `projects` array**: MUST resolve normally with an empty list.
- **Network failure or unreachable server**: The failure from the transport MUST propagate unchanged; no retry happens inside the read operation, and the cached state defers retries to the shared cache.
- **Timeout**: The concept sets no timeout; a hanging request MUST stay pending until the transport or the host gives up.
- **Cancellation**: The cached state's fetch does not forward the shared cache's cancellation signal to the transport; a cancelled query's request MUST keep running, and if it succeeds it still disarms the latch.
- **Arm during an in-flight fetch**: The arm is lost when that fetch succeeds; see the open question on latch-arm-during-flight.
- **Several shared caches in one process**: The latch is shared process-wide, so the first successful fetch in any cache MUST disarm it for all.
- **Server-side rendering**: The concept requires a live client execution context; its latch is initialized per client realm on load.
- **Offline**: No offline handling exists; requests fail as network failures.

