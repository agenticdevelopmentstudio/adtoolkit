import XCTest
import Foundation
import AgenticToolkitCore
import AIPluginKit
@testable import AgenticToolkitDatabase

/// Shared fakes for exercising `DaemonAIChat`/`DaemonSessionSummarizer`'s plugin
/// path without a real `.aiplugin` bundle, network, or subprocess.

/// Seeds the config-UUID-keyed provider registry exactly as a host's provider-config
/// push leaves it — each configuration's plain fields, field ledger and model in the
/// settings table, its secrets in `secretStore`, the identity index, then the
/// summaries switch on and `id` selected. Shared by the summarizer and
/// guard-chokepoint suites.
func selectProviderConfig(
    _ id: UUID,
    plugin: String = "test.fake",
    template: String = "custom",
    model: String,
    values: [String: String] = [:],
    secrets: [String: String] = [:],
    database: DaemonDatabase,
    secretStore: any SecretStoring
) {
    for (key, value) in values {
        try? database.setSetting(AIProviderConfigKeys.fieldKey(config: id, field: key), value)
    }
    try? database.setSetting(AIProviderConfigKeys.fieldsKey(config: id), values.keys.sorted().joined(separator: "\n"))
    try? database.setSetting(AIProviderConfigKeys.modelKey(config: id), model)
    for (field, value) in secrets where !value.isEmpty {
        _ = secretStore.set(value, forKey: AIProviderConfigKeys.fieldKey(config: id, field: field))
    }
    try? database.setSetting(AIProviderConfigKeys.secretFieldsKey(config: id), secrets.keys.sorted().joined(separator: "\n"))
    let identities = [AIProviderConfiguration(id: id, name: "T", pluginIdentifier: plugin, templateId: template)]
    if let data = try? JSONEncoder().encode(identities), let json = String(data: data, encoding: .utf8) {
        try? database.setSetting(AIProviderConfigKeys.configurationsKey, json)
    }
    try? database.setSetting(AIProviderConfigKeys.enabledKey, "true")
    try? database.setSetting(AIProviderConfigKeys.selectedConfigIdKey, id.uuidString)
}

enum FakeError: Error, LocalizedError {
    case boom
    // A stable, predictable description so a test can assert it propagates through
    // the daemon's error mapping (the default Error string would be opaque).
    var errorDescription: String? { "boom" }
}

/// An `AIPlugin` that records the context it was asked to build a request for, so
/// tests can assert what the daemon resolved. Returns a throwaway HTTP spec; the
/// stream itself comes from the injected `PluginRuntime.run`, not the transport.
final class CapturingPlugin: AIPlugin {

    final class Captured: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: AIChatContext?
        var context: AIChatContext? {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    let captured: Captured

    init() { self.captured = Captured() }
    init(captured: Captured) { self.captured = captured }

    func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        captured.context = context
        return .http(url: URL(string: "https://example.invalid/v1")!)
    }

    func makeDecoder() -> any AIStreamDecoder { NoopDecoder() }
}

final class NoopDecoder: AIStreamDecoder {
    func consume(_ data: Data) -> [AIStreamEvent] { [] }
}

/// Builds a canned plugin runtime that returns a fixed `CapturingPlugin` +
/// descriptor and streams `events` (or throws `error`) — no real bundle, network,
/// or `dlopen` involved. The descriptor's `identifier` is the literal `"test.fake"`
/// (matching `DaemonSummarizerPluginTests.pluginId`); `PluginRuntime.load` ignores
/// its arguments, so the identifier is metadata only and doesn't affect resolution.
func makeRuntime(
    captured: CapturingPlugin.Captured,
    events: [AIStreamEvent],
    error: FakeError? = nil
) -> DaemonSessionSummarizer.PluginRuntime {
    let plugin = CapturingPlugin(captured: captured)
    let descriptor = AIPluginDescriptor(
        identifier: "test.fake",
        displayName: "Test Fake",
        version: "1.0",
        models: ["fake-small", "fake-large"],
        defaultModel: "fake-small",
        fields: [
            AIPluginDescriptor.Field(key: "apiKey", label: "API Key", kind: .secret),
            AIPluginDescriptor.Field(key: "baseURL", label: "Base URL", kind: .text)
        ]
    )
    return DaemonSessionSummarizer.PluginRuntime(
        load: { _, _ in (plugin, descriptor) },
        run: { _, _ in
            AsyncThrowingStream { continuation in
                if let error {
                    continuation.finish(throwing: error)
                } else {
                    for event in events { continuation.yield(event) }
                    continuation.finish()
                }
            }
        }
    )
}
