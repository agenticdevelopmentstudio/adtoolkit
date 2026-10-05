
- **SwiftUI**: The sources are
  `packages/apple/AgenticToolkit/Core/AIPlugins/ChatStreamEvent.swift`,
  `ToolDefinition.swift`, and `ToolResult.swift`, part of the
  `AgenticToolkitCore` framework target, which `project.yml` declares as
  `platform: macOS` only (no iOS target exists for it today). Nothing in
  the three files is SwiftUI-specific — each imports only `Foundation` —
  so a SwiftUI or AppKit host consumes them identically.
- **Compose**: Model `ChatStreamEvent` as a Kotlin `sealed interface` with
  data classes `TextDelta(val text: String)`, `ToolUse(val id: String, val
  name: String, val argumentsJson: ByteArray)`, and `End(val stopReason:
  String?)`, matched with an exhaustive `when` expression. Model
  `ToolDefinition` and `ToolResult` as immutable `data class`es
  (`ToolDefinition(val name: String, val description: String, val
  parametersJsonSchema: ByteArray)`, `ToolResult(val toolUseId: String, val
  content: String, val isError: Boolean)`); `Hashable` conformance is free
  on a Kotlin `data class` (structural `equals`/`hashCode`).
- **React/Web**: Represent `ChatStreamEvent` as a discriminated union —
  `{ kind: 'textDelta', text: string } | { kind: 'toolUse', id: string,
  name: string, argumentsJSON: Uint8Array } | { kind: 'end', stopReason?:
  string }` — and `ToolDefinition`/`ToolResult` as `readonly`-field
  interfaces (`{ readonly name: string; readonly description: string;
  readonly parametersJSONSchema: Uint8Array }`, `{ readonly toolUseId:
  string; readonly content: string; readonly isError: boolean }`). There
  is no built-in structural-equality operator, so porting
  `definition-equality`/`result-equality` requires a manual
  deep-equality helper (or a library) rather than a free `==`.
- **AppKit / UIKit**: this is the source. `ChatStreamEvent.swift`,
  `ToolDefinition.swift`, and `ToolResult.swift` live in
  `packages/apple/AgenticToolkit/Core/AIPlugins/`, part of the
  `AgenticToolkitCore` framework target, which `project.yml` declares as
  `platform: macOS` only (no iOS target exists for it today).
  `ChatStreamEvent` is a `Sendable` enum with cases `textDelta(String)`,
  `toolUse(id: String, name: String, argumentsJSON: Data)`, and
  `end(stopReason: String?)`; `ToolDefinition` and `ToolResult` are
  `Sendable`, `Hashable` structs (`ToolDefinition(name: String,
  description: String, parametersJSONSchema: Data)`,
  `ToolResult(toolUseId: String, content: String, isError: Bool)`) with
  every stored property declared `let`. `ChatStreamEvent` mirrors the
  sibling `AIStreamEvent` (in `AIPluginKit`) case-for-case;
  `AIPluginChatBackend.chatEvent(for:)` maps one to the other with no
  transformation. `ToolDefinition` mirrors `AIToolSpec`;
  `LocalChatSession.withTools(_:)` and `AIPluginChatBackend.aiToolSpec(for:)`
  each copy its three fields unchanged into an `AIToolSpec`.
  `ChatStreamEvent` belongs to the `ChatBackend` protocol
  (`ChatBackend.swift`), marked deprecated in favor of
  `ChatSession`/`AIPluginKit` — the current, non-deprecated tool loop
  (`LocalChatSession`) consumes `AIStreamEvent` directly from its
  `EventStreamFactory` and never touches `ChatStreamEvent`. No call site in
  this codebase constructs a `ToolResult`; `LocalChatSession.runTurn`
  instead builds an `AIChatMessage(role: .toolResult, ...)` directly from
  the `(content: String, isError: Bool)` tuple
  `ChatToolSource.callTool(name:argumentsJSON:)` returns.
  `MCPChatToolSource.callTool` decodes `argumentsJSON` with `try?
  JSONDecoder().decode([String: Value].self, from: argumentsJSON)`,
  tolerating a decode failure by passing `nil` arguments onward. The
  cross-domain-safety test vector exercises a `[ToolDefinition]` captured
  in the `@Sendable` closure `AIPluginChatBackend.makeInputs(messages:tools:)`
  builds inside a `MainActor.run` block, read inside `Self.drive`'s
  background `Task`, compiling under `SWIFT_STRICT_CONCURRENCY: complete`.
- **WinUI 3**: Model `ChatStreamEvent` as an abstract `record` with three
  sealed derived records — `TextDelta(string Text)`, `ToolUse(string Id,
  string Name, byte[] ArgumentsJson)`, `End(string? StopReason)` —
  enabling exhaustive `switch` pattern matching over `is` patterns, the
  closest .NET analogue to a closed Swift enum. Model `ToolDefinition` and
  `ToolResult` as `record`s so equality is free, mirroring the synthesized
  `Hashable` — e.g. `public sealed record ToolDefinition(string Name,
  string Description, byte[] ParametersJsonSchema);` and `public sealed
  record ToolResult(string ToolUseId, string Content, bool IsError);`. Use
  `System.Text.Json`'s `JsonDocument`/`Utf8JsonReader` only where a
  consumer needs to inspect `ParametersJsonSchema`/`ArgumentsJson` — never
  inside these three ports themselves, matching `definition-schema-opaque`
  and `tool-use-arguments-raw` above, which require the bytes to pass
  through unparsed. A WinUI 3 chat surface would carry these records
  across `Task`-based async calls the same way the source crosses `Task`
  boundaries — no `ObservableCollection`/`INotifyPropertyChanged` is
  needed for the records themselves, since, like their Swift counterparts,
  they are immutable value snapshots rather than observable view-model
  state.

