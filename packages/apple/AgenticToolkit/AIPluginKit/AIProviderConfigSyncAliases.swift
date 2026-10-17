import AgenticToolkitCore

// The AI provider wire contract moved down to Core (`Core/Stenographer/`) so an
// HTTP client can send it without importing the plugin layer. These aliases keep
// every existing `import AIPluginKit` call site compiling unchanged.

/// See ``AgenticToolkitCore/AIProviderConfigSync``.
public typealias AIProviderConfigSync = AgenticToolkitCore.AIProviderConfigSync
/// See ``AgenticToolkitCore/ResolvedProviderConfig``.
public typealias ResolvedProviderConfig = AgenticToolkitCore.ResolvedProviderConfig
