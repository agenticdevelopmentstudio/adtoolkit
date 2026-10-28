import Foundation

/// Which Stenographer this process belongs to.
///
/// The **default** instance is the one a person installs. It is unnamed and
/// resolves every value exactly as Stenographer always has. A **named**
/// instance (`dev-trimming`) is a development copy that runs beside the
/// installed one. It has its own data root, label, Mach service, port, socket
/// and drop directory, and it never touches what the installed copy owns (see
/// the passive gates in the daemon's `InstancePolicy` and the app's
/// `StenographerInstances`).
///
/// A named instance exists only if its definition file does:
/// `~/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances/<name>.json`,
/// written by `scripts/stenographer_instance.py`. Asking for a name with no
/// definition is a hard error. Creating an empty store for a typo would look
/// like data loss.
public struct StenographerInstance: Sendable, Equatable {

    public struct Definition: Codable, Sendable, Equatable {
        public let name: String
        public let dataRoot: String
        public let httpPort: Int

        public init(name: String, dataRoot: String, httpPort: Int) {
            self.name = name
            self.dataRoot = dataRoot
            self.httpPort = httpPort
        }
    }

    public enum ResolutionError: Error, Equatable, CustomStringConvertible {
        case invalidName(String)
        case undefined(name: String, expectedAt: String)
        case unreadable(path: String, reason: String)
        case nameMismatch(file: String, declared: String)
        case relativeDataRoot(String)
        case invalidPort(Int)
        case socketPathTooLong(path: String, limit: Int)

        public var description: String {
            switch self {
            case .invalidName(let name):
                return "instance name '\(name)' must match [a-z0-9][a-z0-9-]{0,31}"
            case .undefined(let name, let path):
                return "instance '\(name)' is not defined (no \(path)); "
                    + "create it with scripts/stenographer_instance.py create"
            case .unreadable(let path, let reason):
                return "instance definition \(path) is unreadable: \(reason)"
            case .nameMismatch(let file, let declared):
                return "instance definition \(file).json declares name '\(declared)'"
            case .relativeDataRoot(let root):
                return "instance dataRoot '\(root)' must be an absolute path"
            case .invalidPort(let port):
                return "instance httpPort \(port) must be 1024-65535 and not \(StenographerInstance.defaultHTTPPort)"
            case .socketPathTooLong(let path, let limit):
                return "instance socket path \(path) is \(path.utf8.count) bytes; the limit is under \(limit)"
            }
        }
    }

    public static let baseLabel = "com.agenticdevelopmentstudio.stenographer"
    public static let defaultHTTPPort = 22847
    public static let environmentKey = "STENOGRAPHER_INSTANCE"
    public static let argumentFlag = "-instance"
    /// `sockaddr_un.sun_path` is 104 bytes on Darwin, including the NUL.
    public static let socketPathLimit = 104
    public static let socketFileName = "stenographer.sock"

    public static let `default` = StenographerInstance(definition: nil)

    /// nil for the default instance.
    public let definition: Definition?

    init(definition: Definition?) { self.definition = definition }

    public var isDefault: Bool { definition == nil }
    public var name: String? { definition?.name }
    public var label: String { definition.map { "\(Self.baseLabel).\($0.name)" } ?? Self.baseLabel }
    public var httpPort: Int { definition?.httpPort ?? Self.defaultHTTPPort }
    public var dataRoot: URL? { definition.map { URL(fileURLWithPath: $0.dataRoot, isDirectory: true) } }

    public static func definitionsDirectory(home: URL) -> URL {
        home.appendingPathComponent("Library/Application Support/\(baseLabel).instances", isDirectory: true)
    }

    /// The name this process was asked to be, or nil for the default. The
    /// environment wins over the argument: the daemon and the CLI are selected
    /// by environment, and an app passes its own selection to the daemon the
    /// same way.
    public static func requestedName(environment: [String: String], arguments: [String]) -> String? {
        if let value = environment[environmentKey] {
            return value.isEmpty ? nil : value
        }
        guard let flag = arguments.firstIndex(of: argumentFlag), flag + 1 < arguments.count else { return nil }
        let value = arguments[flag + 1]
        return value.isEmpty ? nil : value
    }

    public static func resolve(name: String?, home: URL) throws -> StenographerInstance {
        guard let name else { return .default }
        guard name.wholeMatch(of: /[a-z0-9][a-z0-9-]{0,31}/) != nil else { throw ResolutionError.invalidName(name) }
        let file = definitionsDirectory(home: home).appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw ResolutionError.undefined(name: name, expectedAt: file.path)
        }
        let definition: Definition
        do {
            definition = try JSONDecoder().decode(Definition.self, from: Data(contentsOf: file))
        } catch {
            throw ResolutionError.unreadable(path: file.path, reason: String(describing: error))
        }
        try validate(definition, fileName: name)
        return StenographerInstance(definition: definition)
    }

    /// The rules a definition must satisfy. `scripts/stenographer_instance.py`
    /// enforces the same ones when it writes a definition.
    public static func validate(_ definition: Definition, fileName: String) throws {
        guard definition.name == fileName else {
            throw ResolutionError.nameMismatch(file: fileName, declared: definition.name)
        }
        guard definition.dataRoot.hasPrefix("/") else { throw ResolutionError.relativeDataRoot(definition.dataRoot) }
        guard (1024...65535).contains(definition.httpPort), definition.httpPort != defaultHTTPPort else {
            throw ResolutionError.invalidPort(definition.httpPort)
        }
        let socket = URL(fileURLWithPath: definition.dataRoot, isDirectory: true)
            .appendingPathComponent(socketFileName).path
        guard socket.utf8.count < socketPathLimit else {
            throw ResolutionError.socketPathTooLong(path: socket, limit: socketPathLimit)
        }
    }

    /// This process's instance, resolved once. A process asked to be an
    /// instance that cannot be resolved exits 78 (EX_CONFIG) with the reason on
    /// stderr. That is a normal exit, so launchd's `KeepAlive: {Crashed: true}`
    /// does not relaunch it into the same failure.
    public static let current: StenographerInstance = {
        let info = ProcessInfo.processInfo
        let name = requestedName(environment: info.environment, arguments: info.arguments)
        do {
            return try resolve(name: name, home: FileManager.default.homeDirectoryForCurrentUser)
        } catch {
            FileHandle.standardError.write(Data("stenographer: \(error)\n".utf8))
            exit(78)
        }
    }()
}
