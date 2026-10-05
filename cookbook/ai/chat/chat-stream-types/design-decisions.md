
**Decision**: the stream event duplicates the sibling stream-event
contract (same three cases, same payload shapes) instead of the chat layer
reusing that contract directly.
**Rationale**: (Swift implementation) `ChatStreamEvent` belongs to the
`ChatBackend` protocol (`ChatBackend.swift`), whose own doc comment marks
it "Deprecated. New code conforms to `ChatSession`" — it predates the
newer `ChatSession`/`AIPluginKit` split. `AIPluginChatBackend.chatEvent(for:)`
is a pure field-for-field mapping between the two shapes, and the current,
non-deprecated tool loop (`LocalChatSession`) consumes `AIStreamEvent`
directly from its `EventStreamFactory` and never touches `ChatStreamEvent`
at all. The duplication is a migration artifact tracked by the deprecation
notice on `ChatBackend`, not an independent design need.
**Approved**: pending

**Decision**: the tool result is fully declared (three required fields, an
explicit way to construct it, equality and cross-domain-safety support)
but no call site in this codebase currently constructs one.
**Rationale**: (Swift implementation) its own doc comment describes it as
what "the chat dispatch loop builds... from MCP responses," but the one
dispatch loop present, `LocalChatSession.runTurn`, instead builds an
`AIChatMessage(role: .toolResult, ...)` directly from the `(content,
isError)` tuple `ChatToolSource.callTool(name:argumentsJSON:)` returns.
This mirrors the sibling stream-event recipe's observation about its own
tool-use case: a fully and correctly specified part of a contract that no
current implementation happens to exercise is a source-fidelity note about
integration status, not a gap in the shape's own definition.
**Approved**: pending

**Decision**: None of the stream event, the tool definition, or the tool
result validates the well-formedness of any string or byte field it
carries (a tool description MAY be empty, the raw JSON arguments/
parameter-schema bytes MAY be non-JSON bytes).
**Rationale**: All three are pure carriers between a model-facing backend
and a chat UI or tool source; validation is deferred entirely to whichever
consumer reads the field — e.g. an MCP-backed tool source decodes its raw
arguments with a tolerant decode, passing nothing onward rather than the
value rejecting construction. This matches the same no-validation
convention the chat-context recipe documents for the tool specification's
parameter-schema bytes.
**Approved**: pending

