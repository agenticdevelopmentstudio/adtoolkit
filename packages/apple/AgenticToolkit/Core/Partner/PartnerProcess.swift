import Foundation
import os

/// The partner's long-running `claude` process, seen as typed messages in and out.
public protocol PartnerProcessing: Sendable {
    func start() async throws
    func send(_ text: String) async throws
    /// Decoded stdout. Ends when the process ends.
    func messages() -> AsyncStream<ClaudeStreamMessage>
    func terminate() async
    var isRunning: Bool { get async }
}

/// `claude -p --input-format stream-json` over a `SubprocessChannel`.
public actor PartnerProcess: PartnerProcessing {
    private static let logger = Logger(subsystem: "AgenticToolkit", category: "PartnerProcess")

    private let channel: SubprocessChannel
    private nonisolated let stream: AsyncStream<ClaudeStreamMessage>
    private nonisolated let continuation: AsyncStream<ClaudeStreamMessage>.Continuation
    private var pump: Task<Void, Never>?

    public init(configuration: PartnerProcessConfiguration, environment: [String: String]) {
        self.init(executable: configuration.executable, arguments: configuration.arguments,
                  environment: environment, workingDirectory: configuration.workingDirectory)
    }

    init(executable: String, arguments: [String], environment: [String: String],
         workingDirectory: String? = nil) {
        channel = SubprocessChannel(configuration: .init(
            executableURL: URL(fileURLWithPath: executable),
            arguments: arguments,
            environment: environment,
            environmentPolicy: .mergeOverParent,
            framing: .newlineDelimited,
            currentDirectoryURL: workingDirectory.map { URL(fileURLWithPath: $0) }))
        (stream, continuation) = AsyncStream.makeStream(of: ClaudeStreamMessage.self)
    }

    public func start() async throws {
        try await channel.launch()
        let lines = try await channel.messages()
        let continuation = continuation
        pump = Task {
            do {
                for try await line in lines {
                    do { continuation.yield(try ClaudeStreamMessage.decode(line)) } catch {
                        Self.logger.debug("skipped an undecodable stdout line")
                    }
                }
            } catch {
                Self.logger.debug("stdout ended with an error: \(String(describing: error))")
            }
            continuation.finish()
        }
    }

    public func send(_ text: String) async throws {
        try await channel.sendRaw(ClaudeStreamInput.userMessage(text))
    }

    public nonisolated func messages() -> AsyncStream<ClaudeStreamMessage> { stream }

    public func terminate() async {
        await channel.terminate()
        await pump?.value
        continuation.finish()
    }

    public var isRunning: Bool {
        get async { await channel.isRunning }
    }

    public func standardErrorText() async -> String { await channel.standardErrorText() }
}
