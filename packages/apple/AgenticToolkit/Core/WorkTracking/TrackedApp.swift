import Foundation

/// How a tracked app's working path is found.
public enum PathResolverKind: String, Sendable, Codable { case document, editor, terminal, none }

/// One app whose frontmost time is recorded.
public struct TrackedApp: Sendable, Equatable, Codable, Identifiable {
    public let bundleId: String
    public let name: String
    public let resolver: PathResolverKind
    public var id: String { bundleId }

    public init(bundleId: String, name: String, resolver: PathResolverKind) {
        self.bundleId = bundleId
        self.name = name
        self.resolver = resolver
    }
}

/// The development apps that are recorded: the defaults, minus what the user
/// removed, plus what they added. Anything else is never stored.
public struct AppAllowlist: Sendable, Equatable {
    public static let defaults: [TrackedApp] = [
        TrackedApp(bundleId: "com.apple.dt.Xcode", name: "Xcode", resolver: .document),
        TrackedApp(bundleId: "com.apple.iphonesimulator", name: "Simulator", resolver: .none),
        TrackedApp(bundleId: "com.apple.dt.Instruments", name: "Instruments", resolver: .none),
        TrackedApp(bundleId: "com.google.android.studio", name: "Android Studio", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.intellij", name: "IntelliJ IDEA", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.intellij.ce", name: "IntelliJ IDEA CE", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.pycharm", name: "PyCharm", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.pycharm.ce", name: "PyCharm CE", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.WebStorm", name: "WebStorm", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.goland", name: "GoLand", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.CLion", name: "CLion", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.rubymine", name: "RubyMine", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.rider", name: "Rider", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.PhpStorm", name: "PhpStorm", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.rustrover", name: "RustRover", resolver: .editor),
        TrackedApp(bundleId: "com.jetbrains.fleet", name: "Fleet", resolver: .editor),
        TrackedApp(bundleId: "com.microsoft.VSCode", name: "Visual Studio Code", resolver: .editor),
        TrackedApp(bundleId: "com.microsoft.VSCodeInsiders", name: "VS Code Insiders", resolver: .editor),
        TrackedApp(bundleId: "com.todesktop.230313mzl4w4u92", name: "Cursor", resolver: .editor),
        TrackedApp(bundleId: "com.exafunction.windsurf", name: "Windsurf", resolver: .editor),
        TrackedApp(bundleId: "dev.zed.Zed", name: "Zed", resolver: .document),
        TrackedApp(bundleId: "com.panic.Nova", name: "Nova", resolver: .document),
        TrackedApp(bundleId: "com.barebones.bbedit", name: "BBEdit", resolver: .document),
        TrackedApp(bundleId: "com.sublimetext.4", name: "Sublime Text", resolver: .document),
        TrackedApp(bundleId: "com.apple.Terminal", name: "Terminal", resolver: .terminal),
        TrackedApp(bundleId: "com.googlecode.iterm2", name: "iTerm2", resolver: .terminal),
        TrackedApp(bundleId: "com.mitchellh.ghostty", name: "Ghostty", resolver: .terminal),
        TrackedApp(bundleId: "dev.warp.Warp-Stable", name: "Warp", resolver: .terminal),
        TrackedApp(bundleId: "com.fournova.Tower3", name: "Tower", resolver: .none),
        TrackedApp(bundleId: "com.sublimemerge", name: "Sublime Merge", resolver: .none),
        TrackedApp(bundleId: "com.DanPristupov.Fork", name: "Fork", resolver: .none),
        TrackedApp(bundleId: "com.github.GitHubClient", name: "GitHub Desktop", resolver: .none)
    ]

    /// Defaults minus removed, plus added, sorted by name.
    public let apps: [TrackedApp]
    private let byId: [String: TrackedApp]

    public init(preferences: WorkTrackingPreferences, defaults: [TrackedApp] = AppAllowlist.defaults) {
        let removed = Set(preferences.removedBundleIds)
        var list = defaults.filter { !removed.contains($0.bundleId) }
        let known = Set(defaults.map(\.bundleId))
        for id in Set(preferences.addedBundleIds) where !known.contains(id) && !removed.contains(id) {
            list.append(TrackedApp(bundleId: id, name: id, resolver: .editor))
        }
        list.sort { ($0.name, $0.bundleId) < ($1.name, $1.bundleId) }
        apps = list
        byId = Dictionary(list.map { ($0.bundleId, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public func isAllowed(_ bundleId: String) -> Bool { byId[bundleId] != nil }

    public func app(for bundleId: String) -> TrackedApp? { byId[bundleId] }
}
