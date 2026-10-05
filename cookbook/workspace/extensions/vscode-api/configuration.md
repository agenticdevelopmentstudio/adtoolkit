
| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `path` | a string | none (required) | The namespace member's dotted path; used only in log lines, dispatch-unavailable/teardown messages, and the not-implemented error's member-path — never read back to decide behavior. |
| `owner` | any owning adaptor instance | none (required) | The adaptor instance a member's body runs against; captured weakly when the member is installed. |
| `whenTornDown` | a teardown-response value | none (required) | Chooses whether a call after the owner's deallocation raises an exception or rejects a promise. |
| `members` | a name-to-value mapping | empty | The implemented members of a sub-namespace; every other key throws a not-implemented error. |
| `recordMiss` | an optional callback taking a string | none | Optional hook invoked with an unimplemented member's path, in addition to the thrown error. |
| `recordProbe` | an optional callback taking a string | none | Optional hook invoked with a quietly-missed member's path from the existence/descriptor traps. |
| `maximumDecodableArrayLength` | an integer constant | 100,000 | The hard ceiling the array-length reader enforces on any array-like value's decoded length; not overridable per call. |

