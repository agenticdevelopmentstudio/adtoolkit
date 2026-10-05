
| ID | Requirements | Input | Expected |
|----|---------------|-------|----------|
| scripting-001 | script-compilation-and-execution, success-result-value | A source string that returns the text "hello" | A success result carrying "hello" |
| scripting-002 | success-result-value | A source string that returns the number 42 | A success result carrying "42" — the scripting engine stringifies the numeric result |
| scripting-003 | success-value-nilable | An empty source string | Compiles and executes; returns a success result carrying an absent value |
| scripting-004 | runtime-failure-result | A source string that raises an error with message "boom" and number -1728 | A runtime-failed result whose message contains "boom" and whose number equals -1728 |
| scripting-005 | runtime-failure-fallback-values | An error description with no message or number entries | message equals "unknown error", number equals `0` |
| scripting-006 | compile-failure-result | A source string for which compilation itself fails | A compile-failed result (this path is documented as unreachable in practice by the reference test suite's own comment; the case exists purely as a defensive catch — see Design Decisions) |
| scripting-007 | result-value-equality | Two success results, each carrying the same textual value | They compare equal |
| scripting-008 | runner-caller-thread | The script-running operation invoked from a background execution context | Executes and returns synchronously on that same background context, with no internal hop to another thread or queue |
| scripting-009 | caller-main-thread-marshaling | A background-context caller invokes the script-running operation without marshaling to the main thread, on a system version where the engine requires it | Documented as the caller's own responsibility; the operation performs no thread check or automatic marshaling |
| scripting-010 | command-default-behavior | A command base instance with no subclass override, asked to perform its default implementation | Returns an absent value |
| scripting-011 | command-result-propagation, command-return-type-freedom | A subclass override that returns the text "answer" | The default-implementation operation returns "answer" |
| scripting-012 | command-return-type-freedom | A subclass override that returns the number 42 | The default-implementation operation returns 42 |
| scripting-013 | command-result-propagation | A subclass override that returns an absent value | The default-implementation operation returns an absent value |
| scripting-014 | command-runs-on-serialized-context, command-default-implementation-bridges-context | A subclass override that records whether it observed the main thread, invoked through the default-implementation operation from the main thread | The override observes the main thread as true |
| scripting-016 | element-specifier-result, element-specifier-no-container-specifier, element-specifier-runs-on-serialized-context | The element-locator helper called with key "panes" and a unique-id closure returning "some-uuid", while the application's own class description resolves to a scripting class description | Returns a locator whose key is "panes", whose unique id is "some-uuid", and whose container locator is absent |
| scripting-017 | element-specifier-nil-fallback | The element-locator helper called while the application's own class description does not resolve to a scripting class description | Returns an absent value |

A prior vector verified that a command-base instance handed to the scripting
bridge's arbitrary-thread event dispatch compiles with no concurrency-safety
diagnostic under strict concurrency checking. That guarantee is a compile-time
property of the command base's declared concurrency escape hatch (see Platform Notes and Design Decisions), not an independently
observable input/output behavior, so it is not restated as a numbered vector
here.

