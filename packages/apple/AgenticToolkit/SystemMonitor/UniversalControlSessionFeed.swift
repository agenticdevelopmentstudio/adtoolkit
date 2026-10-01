import AgenticToolkitCore
import Foundation
import Synchronization

/// Where `UniversalControlMonitor` gets its log entries from.
public protocol UniversalControlSessionSource: Sendable {
    /// Starts handing entries to `deliver`, on any thread. Only the first
    /// call starts anything; later ones return at once.
    func start(deliver: @escaping @Sendable (UniversalControlSessionEntry) -> Void)
    /// Why the log could not be read, while it cannot; `nil` once it can.
    var failure: String? { get }
}

/// Universal Control's session messages from the unified log: the last hour
/// once, read at start, and then each as it is written.
///
/// The stream is a `log stream` child process, relaunched whenever it ends —
/// it ends by itself after `UniversalControlSessionLog.streamArguments`'s
/// timeout — until this feed is freed.
public final class UniversalControlSessionFeed: UniversalControlSessionSource {

    public static let restartDelay: Duration = .seconds(2)

    private let executableURL: URL
    private let streamArguments: [String]
    private let historyArguments: [String]?
    private let tasks = Mutex<[Task<Void, Never>]>([])
    private let lastFailure = Mutex<String?>(nil)

    /// - Parameter historyArguments: `nil` to start from the stream alone.
    public init(
        executableURL: URL = UniversalControlSessionLog.logTool,
        streamArguments: [String] = UniversalControlSessionLog.streamArguments(),
        historyArguments: [String]? = UniversalControlSessionLog.historyArguments()
    ) {
        self.executableURL = executableURL
        self.streamArguments = streamArguments
        self.historyArguments = historyArguments
    }

    deinit {
        tasks.withLock { tasks in tasks.forEach { $0.cancel() } }
    }

    public var failure: String? { lastFailure.withLock { $0 } }

    public func start(deliver: @escaping @Sendable (UniversalControlSessionEntry) -> Void) {
        tasks.withLock { tasks in
            guard tasks.isEmpty else { return }
            let url = executableURL
            let stream = streamArguments
            let failure: @Sendable (String?) -> Void = { [weak self] message in
                self?.lastFailure.withLock { $0 = message }
            }
            tasks.append(Task.detached(priority: .utility) {
                while !Task.isCancelled {
                    await Self.read(url, stream, deliver: deliver, failure: failure)
                    try? await Task.sleep(for: Self.restartDelay)
                }
            })
            if let history = historyArguments {
                tasks.append(Task.detached(priority: .utility) {
                    await Self.read(url, history, deliver: deliver, failure: { _ in })
                })
            }
        }
    }

    /// Runs `log` once and delivers each entry it prints, until it exits or
    /// the task is cancelled.
    private static func read(
        _ url: URL,
        _ arguments: [String],
        deliver: @Sendable (UniversalControlSessionEntry) -> Void,
        failure: @Sendable (String?) -> Void
    ) async {
        let channel = SubprocessChannel(configuration: .init(executableURL: url, arguments: arguments))
        await withTaskCancellationHandler {
            do {
                try await channel.launch()
                var delivered = false
                for try await line in try await channel.messages() {
                    guard let entry = UniversalControlSessionLog.parse(line: line) else { continue }
                    if !delivered { failure(nil) }
                    delivered = true
                    deliver(entry)
                }
                let status = try await channel.waitUntilExit()
                if status != 0 {
                    let complaint = await channel.standardErrorText().trimmingCharacters(in: .whitespacesAndNewlines)
                    failure("log exited \(status): \(complaint)")
                } else {
                    failure(nil)
                }
            } catch {
                failure("Could not read the log: \(error.localizedDescription)")
            }
            await channel.terminate()
        } onCancel: {
            Task { await channel.terminate() }
        }
    }
}
