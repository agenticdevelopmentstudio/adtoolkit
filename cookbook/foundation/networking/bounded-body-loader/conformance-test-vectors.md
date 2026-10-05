
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| networking-001 | body-transfer | Limit 1,048,576 bytes (1 MiB); response body of 512 KiB; no misleading declared length. | Returns the full 512 KiB payload, byte for byte, paired with the response value. |
| networking-002 | running-ceiling-check | Limit 4096 bytes; response body of exactly 4096 bytes. | Returns a body of exactly 4096 bytes. |
| networking-003 | running-ceiling-check, overflow-error | Limit 4096 bytes; response body of 4097 bytes; no declared-length header. | Throws the too-large failure; never returns the 4097-byte body. |
| networking-004 | header-ceiling-check, overflow-error | Limit 1000 bytes; response declares an expected length of over a billion bytes but actually sends 10 bytes. | Throws the too-large failure immediately; the 10 bytes are never read into the returned body. |
| networking-005 | chunked-length-fallthrough, running-ceiling-check, overflow-error | Limit 1000 bytes; response declares an expected length of 1 byte but actually sends 4096 bytes. | Throws the too-large failure once the running total exceeds 1000 bytes — not accepted on the strength of the understated declared length. |
| networking-006 | status-agnosticism, overflow-error | Response status 503; body of 64 KiB past a limit of 1024 bytes. | Throws the too-large failure carrying a non-nil response whose status is 503, letting the caller check status ahead of size. |
| networking-007 | underlying-error-propagation | Connection drops mid-transfer before any ceiling is crossed. | Reading the body throws the underlying transport error unchanged, not the too-large failure. |
| networking-008 | cooperative-cancellation | The calling context is cancelled while reading the body is in progress. | The underlying transfer is cancelled and the call throws rather than hanging. |
| networking-009 | stale-callback-tolerance | A data-received or response-received callback arrives for a transfer identifier already removed from the shared state. | The state update returns without effect, without throwing or mutating any other transfer's record. |

