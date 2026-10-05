
- **Data handled**: A text-delta or tool-use stream event MAY carry
  assistant-generated conversational content or the model's raw tool-call
  arguments; the tool definition's description/parameter-schema bytes
  carry host-declared tool metadata rather than end-user data; the tool
  result's content MAY carry whatever a tool execution returns, which, for
  an MCP-backed tool source, can include arbitrary MCP output such as file
  contents or search results. None of the three shapes defines a
  credential or token field of its own.
- **Storage**: None of the three shapes persists anything — each is an
  in-memory value with no file, database, or secure-storage access of its
  own.
- **Transmission**: None of the three shapes transmits data itself; a
  value is only carried in-memory between the model-facing backend that
  produces it and the chat UI or tool source that consumes it.
- **Retention**: None — an instance of any of the three shapes lives only
  as long as the caller holds it (one stream element, one advertised tool,
  one tool outcome); nothing in these shapes extends its lifetime.

