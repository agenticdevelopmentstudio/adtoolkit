
Three small, immutable value shapes carry tool-calling data across the chat
layer: the stream event (one event in the assistant response stream that a
tool-aware chat-backend sending method returns), the tool definition (one
tool advertised to the model, the element a tool source's tool-listing
method returns), and the tool result (the outcome of running one tool
call). None of the three performs I/O; each is a closed, immutable shape
with either a fixed set of cases or an explicit way to construct it from
its parts, and no other logic.

All three have counterparts elsewhere in this cookbook that this recipe
does not otherwise cover. The stream event mirrors — but is a distinct
shape from — the sibling stream-event contract described elsewhere; an
adapter maps one to the other case-for-case with no transformation. The
tool definition similarly mirrors the tool specification described in the
chat-context recipe; the local chat session and that same adapter each
copy a tool definition's three fields unchanged into a tool specification.
The tool result has no current call site in this codebase that constructs
it: the one tool-dispatch loop present builds a chat message with a
tool-result role directly from the content/is-error pair a tool source's
call-tool method returns, rather than a tool-result value — see Design
Decisions.

