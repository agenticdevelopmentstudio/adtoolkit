
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-xpc-protocol-001 | write-reply-shape | save of a client with an empty name | first reply nil; second "A name is required." |
| billing-xpc-protocol-002 | write-reply-shape | successful client save | first reply the stored client JSON; second nil |
| billing-xpc-protocol-003 | list-read-failure | clients read fails | one element: the read-failed row |
| billing-xpc-protocol-004 | count-failure | assign throws | reply -1 |
| billing-xpc-protocol-005 | count-failure | assign finds nothing to move | reply 0 |
| billing-xpc-protocol-006 | entry-writes | save of a billed entry | nil reply with a sentence |
| billing-xpc-protocol-007 | entry-writes | delete of a locked entry | false reply with a sentence |
| billing-xpc-protocol-008 | clients-projects | client read when one is archived | archived client included |
| billing-xpc-protocol-009 | set-preferences | push of an idle cutoff of 9999 minutes | reply carries the clamped 480 |
| billing-xpc-protocol-010 | set-preferences | write failed | empty data reply |
| billing-xpc-protocol-011 | timers | start while another timer runs | the other is closed first |

