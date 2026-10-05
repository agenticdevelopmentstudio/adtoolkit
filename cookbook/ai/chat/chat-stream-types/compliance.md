
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |

`separation-of-concerns` passes because all three files perform no I/O,
storage, or transport of their own — per `no-persistence-no-side-effects`
above, they are only the data shapes shared between a chat backend, a tool
source, and the chat UI, each of which owns its own logic elsewhere.
`explicit-error-handling` passes because `ToolResult` represents a failed
tool call as an explicit `isError: Bool` field on returned data rather than
throwing, swallowing, or logging the failure silently — the same
explicit-outcome shape `ChatToolSource.callTool`'s return tuple already
uses.

`unit-test-coverage` fails because no Swift test references `ChatStreamEvent`, `ToolDefinition` or `ToolResult` under the Apple test targets; the web-side `adhChatBackend.test.ts` and `visitorChatSse.test.ts` exercise a different TypeScript event type, not these shapes.

