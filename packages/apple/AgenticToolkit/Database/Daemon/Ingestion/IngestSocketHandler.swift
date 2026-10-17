#if canImport(AgenticToolkitCore)
import AgenticToolkitCore
import Darwin
import Foundation
import OSLog

/// Listens on a Unix domain socket for hook events forwarded by a daemon's hook
/// script. Each connection is read to EOF, decoded by the injected `decode`
/// closure, and pushed onto a single-consumer FIFO queue. A
/// dedicated drain task pulls events off the queue and hands each to the
/// injected `capture` closure — in the daemon, `IngestSpool.enqueue`.
///
/// Why a queue at all? The daemon's database already serialises writes
/// through its own DispatchQueue, so concurrent connections wouldn't
/// corrupt anything — but the FIFO gives us:
///   1. Stable ingest ordering (events queued in arrival order).
///   2. Bounded memory under backpressure: if the DB stalls, the
///      AsyncStream's buffer caps growth instead of letting accept-task
///      memory unbound.
///
/// Auth: `getpeereid` checks the connecting process's UID against the
/// daemon's UID and rejects mismatches. The socket file is also chmod
/// 0600 so the kernel rejects the connect() before we ever accept.
public final class IngestSocketHandler: @unchecked Sendable {

    // MARK: - Constants

    /// Maximum number of events buffered before backpressure kicks in.
    /// At ~1KB context per event this caps memory at ~1MB. If the DB
    /// stalls hard enough to fill this, oldest events are dropped — see
    /// `acceptLoop`'s yield-result handling.
    private static let queueCapacity = 1024

    /// Maximum bytes accepted per connection. Hook payloads are small
    /// (KB scale) plus env (few KB). 1 MB is comfortably above any
    /// realistic hook and cheap to enforce as a hard ceiling against
    /// runaway senders.
    private static let maxPayloadBytes = 1 << 20

    // MARK: - Properties

    private let socketPath: String
    /// What a received event is handed to. A closure rather than an
    /// ingestion handler, so that the daemon can point both live
    /// capture paths — this socket and `POST /hook/:event` — at the same
    /// `IngestSpool.enqueue`. Two capture paths that write to the main database
    /// by two different routes is two sets of failure modes to reason about;
    /// one queue in front of both is one.
    private let capture: @Sendable (ParsedEvent) throws -> Void
    /// Turns the bytes of one connection into an event, or nil when they are
    /// malformed or not a trackable event. The wire format is the hook script's,
    /// so it belongs to whoever owns that script, not to this listener.
    private let decode: @Sendable (Data) -> ParsedEvent?
    private var listenFD: Int32 = -1
    private var acceptTask: Task<Void, Never>?
    private var drainTask: Task<Void, Never>?
    private var continuation: AsyncStream<ParsedEvent>.Continuation?
    private let isRunning = ManagedAtomic(false)

    // MARK: - Init

    /// - Parameter socketPath: where to bind. The caller decides; a daemon roots
    ///   its hook state in one directory, such as `~/.claude`.
    public init(
        socketPath: String,
        capture: @escaping @Sendable (ParsedEvent) throws -> Void,
        decode: @escaping @Sendable (Data) -> ParsedEvent?
    ) {
        self.socketPath = socketPath
        self.capture = capture
        self.decode = decode
    }

    // MARK: - Lifecycle

    /// Bind, listen, and start the accept + drain tasks. Throws on bind
    /// failure (which usually means the socket dir doesn't exist or is
    /// unwritable). Idempotent: a second `start()` while running is a no-op.
    public func start() throws {
        guard isRunning.compareExchange(expected: false, desired: true) else { return }

        try ensureSocketDirectoryExists()
        // Stale socket file from a previous (crashed) daemon would block bind().
        unlink(socketPath)

        let socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            isRunning.store(false)
            throw SocketError.socketFailed(errno: errno)
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathLength = socketPath.utf8.count
        let maxLength = MemoryLayout.size(ofValue: addr.sun_path) - 1
        guard pathLength <= maxLength else {
            close(socketFD)
            isRunning.store(false)
            throw SocketError.pathTooLong
        }
        withUnsafeMutablePointer(to: &addr.sun_path) { pathPtr in
            pathPtr.withMemoryRebound(to: CChar.self, capacity: maxLength + 1) { cPtr in
                _ = strncpy(cPtr, socketPath, maxLength)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.bind(socketFD, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            let err = errno
            close(socketFD)
            isRunning.store(false)
            throw SocketError.bindFailed(errno: err)
        }

        // Restrict to owner only — defense in depth alongside getpeereid().
        chmod(socketPath, 0o600)

        guard listen(socketFD, 64) == 0 else {
            let err = errno
            close(socketFD)
            unlink(socketPath)
            isRunning.store(false)
            throw SocketError.listenFailed(errno: err)
        }

        self.listenFD = socketFD

        // FIFO queue. `bufferingPolicy: .bufferingOldest` drops the oldest
        // event when full — better than rejecting new ones, since the
        // newest typically has the most current state.
        let (stream, continuation) = AsyncStream.makeStream(
            of: ParsedEvent.self,
            bufferingPolicy: .bufferingOldest(Self.queueCapacity)
        )
        self.continuation = continuation

        // Accept loop runs forever (until cancellation via stop()).
        let acceptFD = socketFD
        let cont = continuation
        let decode = self.decode
        acceptTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.acceptLoop(listenFD: acceptFD, continuation: cont, decode: decode)
        }

        // Drain loop hands each event to capture, in arrival order.
        let capture = self.capture
        drainTask = Task.detached(priority: .userInitiated) {
            for await event in stream {
                do {
                    try capture(event)
                } catch {
                    Self.logger.error("Socket capture failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        Self.logger.info("IngestSocketHandler listening on \(self.socketPath, privacy: .public)")
    }

    /// Stop accepting new connections, drain the queue, remove the
    /// socket file. Safe to call multiple times.
    public func stop() {
        guard isRunning.compareExchange(expected: true, desired: false) else { return }

        if listenFD >= 0 {
            shutdown(listenFD, SHUT_RDWR)
            close(listenFD)
            listenFD = -1
        }
        unlink(socketPath)

        continuation?.finish()
        continuation = nil

        acceptTask?.cancel()
        drainTask?.cancel()
        acceptTask = nil
        drainTask = nil

        Self.logger.info("IngestSocketHandler stopped")
    }

    // MARK: - Accept loop

    private func acceptLoop(
        listenFD: Int32,
        continuation: AsyncStream<ParsedEvent>.Continuation,
        decode: @Sendable (Data) -> ParsedEvent?
    ) async {
        let myUID = getuid()
        while !Task.isCancelled {
            var clientAddr = sockaddr_un()
            var clientLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientFD = withUnsafeMutablePointer(to: &clientAddr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    accept(listenFD, sockPtr, &clientLen)
                }
            }
            if clientFD < 0 {
                // EBADF / EINVAL after stop() closed the listen fd — exit cleanly.
                if errno == EBADF || errno == EINVAL { return }
                if errno == EINTR { continue }
                Self.logger.error("accept failed: errno=\(errno)")
                continue
            }

            // Verify peer credentials. SOCK_STREAM Unix sockets on macOS
            // expose the connecting process's UID via getpeereid; reject
            // anything that isn't the daemon's own user.
            var peerUID = uid_t(0)
            var peerGID = gid_t(0)
            if getpeereid(clientFD, &peerUID, &peerGID) != 0 || peerUID != myUID {
                Self.logger.warning("Rejecting socket connection: peer uid=\(peerUID) != daemon uid=\(myUID)")
                close(clientFD)
                continue
            }

            // Process inline so the queue receives events in arrival
            // order (FIFO contract). A misbehaving client can't stall
            // the loop indefinitely — `handleConnection` sets a recv
            // timeout on the fd before reading.
            Self.handleConnection(fd: clientFD, continuation: continuation, decode: decode)
        }
    }

    // MARK: - Per-connection processing

    private static func handleConnection(
        fd clientFD: Int32,
        continuation: AsyncStream<ParsedEvent>.Continuation,
        decode: @Sendable (Data) -> ParsedEvent?
    ) {
        defer { close(clientFD) }

        // 1-second recv timeout so a stalled client can't block the
        // accept loop. Hook script does fire-and-forget — at most a few
        // KB — so a 1s ceiling is generous.
        var timeout = timeval(tv_sec: 1, tv_usec: 0)
        setsockopt(clientFD, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        guard let data = readToEOF(fd: clientFD, maxBytes: maxPayloadBytes) else {
            return
        }
        guard let parsed = decode(data) else {
            logger.warning("Undecodable socket payload (\(data.count) bytes)")
            return
        }
        let result = continuation.yield(parsed)
        switch result {
        case .terminated:
            // Drain task is shutting down — nothing more to do.
            return
        case .dropped:
            logger.warning("Ingest queue full, dropped event \(parsed.eventType, privacy: .public)")
        case .enqueued:
            return
        @unknown default:
            return
        }
    }

    /// Read from `fd` until EOF or `maxBytes` reached. Returns nil only
    /// on a fatal read error; an empty connection returns empty Data.
    private static func readToEOF(fd readFD: Int32, maxBytes: Int) -> Data? {
        var buffer = Data()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while buffer.count < maxBytes {
            let bytesRead = chunk.withUnsafeMutableBufferPointer { bufPtr in
                read(readFD, bufPtr.baseAddress, bufPtr.count)
            }
            if bytesRead == 0 { return buffer }   // EOF
            if bytesRead < 0 {
                if errno == EINTR { continue }
                return nil
            }
            buffer.append(contentsOf: chunk[0..<Int(bytesRead)])
        }
        // Hit the cap; drop the connection rather than ingest a giant
        // partially-buffered payload.
        logger.warning("Socket payload exceeded \(maxBytes) bytes; rejecting")
        return nil
    }

    // MARK: - Filesystem

    private func ensureSocketDirectoryExists() throws {
        let dir = (socketPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
    }
}

extension IngestSocketHandler: Loggable {
    public static nonisolated let logger = makeLogger()
}

// MARK: - Errors

public enum SocketError: Error, LocalizedError {
    case socketFailed(errno: Int32)
    case bindFailed(errno: Int32)
    case listenFailed(errno: Int32)
    case pathTooLong

    public var errorDescription: String? {
        switch self {
        case .socketFailed(let errno):  return "socket() failed: errno=\(errno)"
        case .bindFailed(let errno):    return "bind() failed: errno=\(errno)"
        case .listenFailed(let errno):  return "listen() failed: errno=\(errno)"
        case .pathTooLong:          return "socket path exceeds sun_path size"
        }
    }
}

// MARK: - Atomic flag

/// Tiny Sendable atomic bool for start/stop guarding. Avoids importing
/// swift-atomics for what amounts to a single `cmpxchg`.
private final class ManagedAtomic: @unchecked Sendable {
    private var value: Int32 = 0
    private let lock = NSLock()

    init(_ initial: Bool) { value = initial ? 1 : 0 }

    func compareExchange(expected: Bool, desired: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let exp: Int32 = expected ? 1 : 0
        if value == exp {
            value = desired ? 1 : 0
            return true
        }
        return false
    }

    func store(_ newValue: Bool) {
        lock.lock()
        value = newValue ? 1 : 0
        lock.unlock()
    }
}
#endif
