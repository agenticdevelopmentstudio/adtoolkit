
No test file exists for this module in the source; these vectors are derived from the function body and standard text-conversion semantics.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| err-001 | error-message-passthrough | An error object with message `"boom"` | `"boom"` |
| err-002 | error-message-passthrough, error-name-omitted | A specialized error subtype (type name `TypeError`) with message `"bad arg"` | `"bad arg"` (no "TypeError: " prefix) |
| err-003 | error-message-passthrough | An error object with an empty message | `""` (empty string) |
| err-004 | string-identity, non-error-string-conversion | `"network down"` | `"network down"` |
| err-005 | nullish-conversion | `null` | `"null"` |
| err-006 | nullish-conversion | `undefined` | `"undefined"` |
| err-007 | non-error-string-conversion | `42` | `"42"` |
| err-008 | plain-object-conversion, instanceof-discrimination | `{ message: "x" }` | `"[object Object]"` |
| err-009 | non-error-string-conversion | an object whose text conversion returns `"custom"` | `"custom"` |
| err-010 | purity | an error object, called twice | same string both times; the error object's own fields are unchanged |
| err-011 | no-prefixing, no-truncation | An error object with message `"  padded  "` | `"  padded  "` exactly |
| err-012 | accepts-any-thrown-value | The module | exports a single error-message operation |

