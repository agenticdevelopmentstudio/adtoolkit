import Foundation
import os

/// The partner's long-running `claude` process, seen as typed messages in and out.
public protocol PartnerProcessing: Sendable {
    func start() async throws
    func send(_ text: String) async throws
    /// Decoded stdout. Ends when the process ends. Single-consumer: the first
    /// call returns the stream, later calls return an already-finished one, and
    /// the consumer must not `break` out of it (that ends the stream for good).
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
    private nonisolated let handedOut = OSAllocatedUnfairLock(initialState: false)
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
        // Detached and capturing no actor state, so the pump never keeps the
        // process alive and decoding stays off the actor's executor.
        pump = Task.detached {
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

    /// Single-consumer: the first call returns the stream, any later call an
    /// already-finished one.
    public nonisolated func messages() -> AsyncStream<ClaudeStreamMessage> {
        let first = handedOut.withLock { handed -> Bool in
            defer { handed = true }
            return !handed
        }
        if first { return stream }
        return AsyncStream { $0.finish() }
    }

    deinit {
        pump?.cancel()
        let channel = channel
        Task.detached { await channel.terminate() }
    }

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
