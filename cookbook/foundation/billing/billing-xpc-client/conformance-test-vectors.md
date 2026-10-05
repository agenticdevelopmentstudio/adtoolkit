
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-xpc-client-001 | failed-read-is-nil | list reply contains the read-failed row | nil |
| billing-xpc-client-002 | failed-read-is-nil | transport throws | nil |
| billing-xpc-client-003 | write-result | daemon returns the stored client JSON | `.success(client)` |
| billing-xpc-client-004 | write-result | daemon refuses with "A name is required." | `.failure` whose message is that sentence |
| billing-xpc-client-005 | write-result | transport throws | `.failure(.unreachable)` ("The daemon isn't answering.") |
| billing-xpc-client-006 | write-result | reply is not valid JSON for the type | `.failure(.unreadable)` |
| billing-xpc-client-007 | refusal-fallback | refusal with nil reason | message "The daemon refused the change." |
| billing-xpc-client-008 | write-timeout | any write | timeout 65 s, retries 0 |
| billing-xpc-client-009 | count-result | reply -1 | nil |
| billing-xpc-client-010 | count-result | reply 0 | 0 |
| billing-xpc-client-011 | preferences-push | reply empty data | false |
| billing-xpc-client-012 | preferences-push | reply non-empty data | true |
| billing-xpc-client-013 | wire-coding | reply with `started_at` and an ISO-8601 date | decoded to `startedAt` and a date |

