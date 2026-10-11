import Foundation

/// A command-line tool an app ships inside its bundle, put on the user's PATH
/// as a symbolic link — `~/.local/bin/adterm` → `ADTerminal.app/Contents/MacOS/adterm`.
///
/// A link rather than a copy, so the tool is always the one that matches the
/// app it talks to, and moving or updating the app needs nothing reinstalled
/// beyond running this again. `~/.local/bin` needs no administrator rights,
/// and is where Claude Code installs itself too.
public struct CommandLineToolLink: Sendable, Equatable {

    public enum State: Sendable, Equatable {
        case notInstalled
        /// The link is there and points at this tool.
        case installed
        /// A link of that name points somewhere else — another copy of the app.
        case linkedElsewhere(String)
        /// Something that is not a link has the name; it is never touched.
        case occupied
    }

    public enum LinkError: Error, LocalizedError, Equatable {
        case toolMissing(String)
        case occupied(String)

        public var errorDescription: String? {
            switch self {
            case .toolMissing(let path): "The tool is not in the app: \(path)"
            case .occupied(let path): "\(path) exists and is not a link, so it was left alone."
            }
        }
    }

    public let name: String
    public let tool: URL
    public let directory: URL

    public init(name: String, tool: URL, directory: URL = Self.userBinDirectory) {
        self.name = name
        self.tool = tool
        self.directory = directory
    }

    /// The tool `bundle` ships as an auxiliary executable (in `Contents/MacOS`),
    /// or nil when it ships none of that name.
    public static func bundled(_ name: String, in bundle: Bundle = .main,
                               directory: URL = userBinDirectory) -> CommandLineToolLink? {
        bundle.url(forAuxiliaryExecutable: name).map { CommandLineToolLink(name: name, tool: $0, directory: directory) }
    }

    /// `~/.local/bin`.
    public static var userBinDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin", isDirectory: true)
    }

    public var linkURL: URL { directory.appendingPathComponent(name) }

    public var state: State {
        let path = linkURL.path
        if let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
            let resolved = URL(fileURLWithPath: destination, relativeTo: directory).standardizedFileURL
            return resolved.path == tool.standardizedFileURL.path ? .installed : .linkedElsewhere(destination)
        }
        return FileManager.default.fileExists(atPath: path) ? .occupied : .notInstalled
    }

    /// Links the tool into ``directory``, creating it if need be and replacing
    /// a link to anywhere else. Refuses to replace anything that is not a link.
    public func install() throws {
        guard FileManager.default.isExecutableFile(atPath: tool.path) else {
            throw LinkError.toolMissing(tool.path)
        }
        switch state {
        case .installed: return
        case .occupied: throw LinkError.occupied(linkURL.path)
        case .linkedElsewhere: try FileManager.default.removeItem(at: linkURL)
        case .notInstalled: break
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: linkURL, withDestinationURL: tool)
    }

    /// Removes the link, wherever it points. Anything that is not a link is
    /// left alone.
    public func uninstall() throws {
        switch state {
        case .installed, .linkedElsewhere: try FileManager.default.removeItem(at: linkURL)
        case .occupied: throw LinkError.occupied(linkURL.path)
        case .notInstalled: return
        }
    }
}
