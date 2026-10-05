
This component's failure descriptions and two diagnostic prefixes are hardcoded, unlocalized English string literals; none has a string-catalog key — the literal is both the value and its own identifier.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no catalog key) | "Malformed frame header: %@" | The malformed-header failure's description, interpolated with the specific reason |
| (none — literal, no catalog key) | "Frame header is missing a Content-Length field." | The missing-content-length failure's description |
| (none — literal, no catalog key) | "Truncated message: expected %d body bytes, received %d." | The truncated-message failure's description |
| (none — literal, no catalog key) | "Frame exceeds the %d-byte cap." | The frame-size-exceeded failure's description |
| (none — literal, no catalog key) | "The subprocess channel has not been launched yet." | The not-launched failure's description |
| (none — literal, no catalog key) | "The subprocess channel has already been launched." | The already-launched failure's description |
| (none — literal, no catalog key) | "messages() has already been called; only one reader is supported." | The already-consumed failure's description |
| (none — literal, no catalog key) | "The subprocess channel's standard input has been closed." | The input-closed failure's description |
| (none — literal, no catalog key) | "Failed to launch the subprocess: %@" | The launch-failed failure's description, interpolated with the failure reason |
| (none — literal, no catalog key) | "The subprocess exited with status %d: %@" | The exited failure's description |
| (none — literal, no catalog key) | "The operation exceeded its %gs budget." | The budget-exceeded failure's description, interpolated with the elapsed seconds |
| (none — literal, no catalog key) | "[stderr truncated to the last 1048576 bytes]\n" | Prefix prepended to standard-error text when the tail cap trimmed the buffer |
| (none — literal, no catalog key) | "[stderr capture incomplete: the drain did not finish within 0.5s]\n" | Prefix prepended to standard-error text when the drain grace lapsed |

