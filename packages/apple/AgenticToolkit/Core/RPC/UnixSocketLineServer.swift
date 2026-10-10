import Foundation

/// A Unix-domain socket that answers one request per connection: the client
/// writes a line, the handler's answer is written back as a line, and the
/// connection closes.
///
/// For a local control channel between an app and a command-line tool run by
/// the same user. A socket file is reachable only by whoever can reach its
/// path, so the server makes the file owner-only, and it also refuses any
/// peer whose user id is not its own — a localhost HTTP port, by contrast, is
/// open to every process on the machine.
public final class UnixSocketLineServer: @unchecked Sendable {

    public typealias Handler = @Sendable (Data) async -> Data

    public let path: String
    private let handler: Handler
    private let maximumRequestBytes: Int
    private let lock = NSLock()
    private var listenDescriptor: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private let acceptQueue = DispatchQueue(label: "UnixSocketLineServer.accept")

    /// - Parameters:
    ///   - path: Where the socket file goes. Whatever is there already is
    ///     removed: a socket left by a process that died is never reused.
    ///   - maximumRequestBytes: A longer request is dropped unanswered.
    ///   - handler: Answers one request line (without its newline).
    public init(path: String, maximumRequestBytes: Int = 1 << 20, handler: @escaping Handler) {
        self.path = path
        self.maximumRequestBytes = maximumRequestBytes
        self.handler = handler
    }

    deinit { stop() }

    public func start() throws {
        lock.lock()
        defer { lock.unlock() }
        guard listenDescriptor < 0 else { return }

        var address = try UnixSocketAddress.make(path)
        unlink(path)
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw UnixSocketError.system(call: "socket", code: errno) }
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0 else {
            let code = errno
            close(descriptor)
            throw UnixSocketError.system(call: "bind", code: code)
        }
        chmod(path, 0o600)
        guard listen(descriptor, 16) == 0 else {
            let code = errno
            close(descriptor)
            unlink(path)
            throw UnixSocketError.system(call: "listen", code: code)
        }
        _ = fcntl(descriptor, F_SETFL, fcntl(descriptor, F_GETFL) | O_NONBLOCK)

        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: acceptQueue)
        source.setEventHandler { [weak self] in self?.acceptPending(on: descriptor) }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        listenDescriptor = descriptor
        acceptSource = source
    }

    /// Stops listening and removes the socket file. Requests already being
    /// answered finish.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard listenDescriptor >= 0 else { return }
        acceptSource?.cancel()
        acceptSource = nil
        listenDescriptor = -1
        unlink(path)
    }

    private func acceptPending(on listener: Int32) {
        while true {
            let client = accept(listener, nil, nil)
            guard client >= 0 else { return }
            var peerUser: uid_t = 0
            var peerGroup: gid_t = 0
            guard getpeereid(client, &peerUser, &peerGroup) == 0, peerUser == getuid() else {
                close(client)
                continue
            }
            _ = fcntl(client, F_SETFL, fcntl(client, F_GETFL) & ~O_NONBLOCK)
            UnixSocketIO.configure(client, timeout: 10)
            // Reading blocks, so it happens on a thread of its own rather than
            // on the accept queue or Swift's cooperative pool.
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                guard let request = try? UnixSocketIO.readLine(client, limit: maximumRequestBytes) else {
                    close(client)
                    return
                }
                let handler = self.handler
                Task.detached {
                    let response = await handler(request)
                    DispatchQueue.global(qos: .userInitiated).async {
                        try? UnixSocketIO.writeAll(client, MessageFraming.newlineDelimited.frame(response))
                        close(client)
                    }
                }
            }
        }
    }
}

/// Sends one line to a ``UnixSocketLineServer`` and returns its one-line answer.
public enum UnixSocketLineClient {

    /// - Parameter timeout: How long to wait for the answer, which for a
    ///   request that runs something can be a long time.
    public static func request(_ payload: Data, path: String, timeout: TimeInterval) throws -> Data {
        var address = try UnixSocketAddress.make(path)
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw UnixSocketError.system(call: "socket", code: errno) }
        defer { close(descriptor) }
        let connected = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard connected == 0 else { throw UnixSocketError.system(call: "connect", code: errno) }
        UnixSocketIO.configure(descriptor, timeout: timeout)
        try UnixSocketIO.writeAll(descriptor, MessageFraming.newlineDelimited.frame(payload))
        return try UnixSocketIO.readLine(descriptor, limit: MessageFramingDecoder.maximumFrameBytes)
    }
}

public enum UnixSocketError: Error, LocalizedError, Equatable {
    /// `sockaddr_un` holds 104 bytes of path, terminator included.
    case pathTooLong(String)
    case system(call: String, code: Int32)
    case timedOut
    case closedWithoutReply
    case tooLarge

    public var errorDescription: String? {
        switch self {
        case .pathTooLong(let path): "Socket path is too long: \(path)"
        case .system(let call, let code): "\(call) failed: \(String(cString: strerror(code)))"
        case .timedOut: "Timed out waiting for a reply"
        case .closedWithoutReply: "The connection closed without a reply"
        case .tooLarge: "The message is too large"
        }
    }
}

private enum UnixSocketAddress {
    static func make(_ path: String) throws -> sockaddr_un {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard bytes.count < capacity else { throw UnixSocketError.pathTooLong(path) }
        withUnsafeMutableBytes(of: &address.sun_path) { buffer in
            buffer.copyBytes(from: bytes)
            buffer[bytes.count] = 0
        }
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        return address
    }
}

private enum UnixSocketIO {

    /// No SIGPIPE when the other side has gone, and no read or write that
    /// waits longer than `timeout`.
    static func configure(_ descriptor: Int32, timeout: TimeInterval) {
        var enabled: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
        let seconds = max(timeout, 0.1)
        var interval = timeval(tv_sec: Int(seconds), tv_usec: Int32((seconds - floor(seconds)) * 1_000_000))
        setsockopt(descriptor, SOL_SOCKET, SO_RCVTIMEO, &interval, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(descriptor, SOL_SOCKET, SO_SNDTIMEO, &interval, socklen_t(MemoryLayout<timeval>.size))
    }

    static func writeAll(_ descriptor: Int32, _ data: Data) throws {
        try data.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let written = write(descriptor, buffer.baseAddress! + offset, buffer.count - offset)
                if written < 0 {
                    let code = errno
                    if code == EINTR { continue }
                    throw code == EAGAIN ? UnixSocketError.timedOut : UnixSocketError.system(call: "write", code: code)
                }
                offset += written
            }
        }
    }

    /// The first line on the socket, without its newline.
    static func readLine(_ descriptor: Int32, limit: Int) throws -> Data {
        var decoder = MessageFramingDecoder(framing: .newlineDelimited)
        var chunk = [UInt8](repeating: 0, count: 64 * 1024)
        var received = 0
        while true {
            let count = read(descriptor, &chunk, chunk.count)
            if count < 0 {
                let code = errno
                if code == EINTR { continue }
                throw code == EAGAIN ? UnixSocketError.timedOut : UnixSocketError.system(call: "read", code: code)
            }
            if count == 0 {
                guard let last = try decoder.finish().first else { throw UnixSocketError.closedWithoutReply }
                return last
            }
            received += count
            guard received <= limit else { throw UnixSocketError.tooLarge }
            if let line = try decoder.consume(Data(chunk[0..<count])).first {
                return line.last == 0x0A ? line.dropLast() : line
            }
        }
    }
}
