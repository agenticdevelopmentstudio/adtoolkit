
- **SwiftUI**: not applicable to this file — `AIChatContext.swift` imports
  only `Foundation`, with no SwiftUI dependency; any SwiftUI-based host or
  plugin consumes these value types unchanged, since all four are
  `Sendable` and carry no UI state.
- **AppKit / UIKit**: this is the source. The file is
  `packages/apple/AgenticToolkit/AIPluginKit/AIChatContext.swift`, part of
  the `AIPluginKit` framework target, which `project.yml` declares as
  `platform: macOS` only (no iOS target exists for it today). It declares
  four Foundation-only, `Sendable` value types: `AIChatMessage` (with a
  `Role: String`-backed enum whose `toolUse`/`toolResult` cases have
  explicit raw values `"tool_use"`/`"tool_result"`), `AIToolSpec`
  (`Hashable` via compiler-synthesized memberwise conformance over `name`,
  `description`, `parametersJSONSchema: Data`), `AIPluginConfig` (wrapping
  a `[String: String]` named `values`, with `apiKey`/`baseURL`/`model` as
  computed properties over `values[...]`, plus a keyed `subscript`), and
  `AIChatContext` itself (`messages: [AIChatMessage]`, `model: String`,
  `systemPrompt: String?`, `maxTokens: Int = 4096`, `tools: [AIToolSpec] =
  []`, `config: AIPluginConfig`). All four are `struct`s
  (`AIChatMessage.Role` is an `enum`) with every stored property declared
  `let`, so immutability and `Sendable` conformance are both
  compiler-enforced; none declares a throwing initializer, matching
  `no-error-domain` — rejecting an insufficient context is `AIPlugin
  .buildRequest(_:) throws`'s job, on the sibling `AIPlugin.swift`.
  `AIPluginConfig`'s doc comment states the plugin never touches storage
  itself; the host is expected to merge the plugin's settings-schema
  fields with secrets it has already read from the Keychain (via whatever
  `SecretStoring` implementation the host uses) before constructing one.
  `AIPluginConfig` declares no `CustomStringConvertible`/
  `CustomDebugStringConvertible` override, so its compiler-synthesized
  default description prints the entire `values` dictionary — including
  any credential — if logged or printed; no current caller
  (`LocalChatSession.swift`, `AIPluginChatBackend.swift`,
  `AIPluginLanguageModelProvider.swift`, `DaemonAIChat.swift`) does so
  today. The unclamped-`maxTokens` edge case above traces to
  `GooglePlugin.swift`, `OpenAICompatiblePlugin.swift`,
  `ClaudeAPIPlugin.swift`, and `OpenAIPlugin.swift`, each of which forwards
  `context.maxTokens` into its provider's request body with no clamping.
- **Compose**: a Kotlin port would model `AIChatMessage`, `AIToolSpec`,
  `AIPluginConfig`, and `AIChatContext` as immutable `data class`es with
  `val` properties; `AIChatMessage.Role` as a `kotlinx.serialization`-backed
  enum whose `@SerialName` values are `"tool_use"`/`"tool_result"`
  (matching the raw-value divergence from the case names); `parametersJSONSchema`
  /`toolArgumentsJSON` as `ByteArray`; `AIToolSpec`'s `Hashable` conformance
  is free on a Kotlin `data class` (structural `equals`/`hashCode`).
- **React/Web**: a TypeScript port would use `readonly`-field interfaces or
  types for all four shapes; `Role` as the string-literal union `'system' |
  'user' | 'assistant' | 'tool_use' | 'tool_result'` (the union members
  already match the raw values, unlike the case names); `Data` fields as
  `Uint8Array` or pre-parsed `unknown`/`JSONSchema` values depending on
  whether the schema travels as raw bytes or parsed JSON on that platform;
  there is no built-in structural-equality operator, so porting
  `tool-spec-equality` requires a manual deep-equality helper (or a
  library) rather than a free `==`.
- **WinUI 3**: a .NET port would model the four types as `record`s so
  equality is free, mirroring the synthesized `Hashable` on `AIToolSpec` —
  e.g. `public sealed record AIToolSpec(string Name, string Description,
  byte[] ParametersJsonSchema);`. `AIChatMessage.Role` would be a C# `enum`
  with `[EnumMember(Value = "tool_use")]`/`[EnumMember(Value =
  "tool_result")]` (or a custom `JsonConverter`) so JSON serialization
  preserves the same raw strings. `AIChatContext` would be a `record` with
  C# default parameter values matching the defaults exactly — `int
  MaxTokens = 4096` and `IReadOnlyList<AIToolSpec> Tools =
  Array.Empty<AIToolSpec>()` — and `AIPluginConfig` would wrap an
  `IReadOnlyDictionary<string, string>` with `ApiKey`/`BaseUrl`/`Model`
  properties reading the same three conventional keys via `TryGetValue`.
  `byte[]` plus `System.Text.Json.JsonSerializer`/`JsonDocument` replace
  Foundation's `Data`/`JSONSerialization` for the two JSON-carrying fields.

