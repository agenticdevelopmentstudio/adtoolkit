import Foundation

/// Everything a daemon's LaunchAgent plist says, as values. ``LaunchAgentPlist``
/// renders it; ``LaunchAgentJob`` writes and registers it.
public struct LaunchAgentSpec: Sendable, Equatable {
    public var label: String
    public var programArguments: [String]
    public var workingDirectory: URL
    public var stdoutPath: URL
    public var stderrPath: URL
    /// Mach service names the job registers. Empty means the plist carries no
    /// `MachServices` key at all (a daemon that speaks HTTP only).
    public var machServices: [String]
    /// `KeepAlive {Crashed: true}`: launchd relaunches the job after a crash
    /// but not after a clean exit. False omits `KeepAlive`.
    public var keepAliveOnCrash: Bool
    public var runAtLoad: Bool
    public var throttleInterval: Int
    public var processType: String
    /// `EnvironmentVariables`; empty omits the key.
    public var environment: [String: String]

    public init(label: String, programArguments: [String], workingDirectory: URL, stdoutPath: URL,
                stderrPath: URL, machServices: [String] = [], keepAliveOnCrash: Bool = true,
                runAtLoad: Bool = true, throttleInterval: Int = 30, processType: String = "Adaptive",
                environment: [String: String] = [:]) {
        self.label = label
        self.programArguments = programArguments
        self.workingDirectory = workingDirectory
        self.stdoutPath = stdoutPath
        self.stderrPath = stderrPath
        self.machServices = machServices
        self.keepAliveOnCrash = keepAliveOnCrash
        self.runAtLoad = runAtLoad
        self.throttleInterval = throttleInterval
        self.processType = processType
        self.environment = environment
    }
}

/// A daemon's LaunchAgent, rendered for the bundle that is running, so an app
/// launched from Downloads, or moved, points launchd at itself.
public enum LaunchAgentPlist {
    public static func render(_ spec: LaunchAgentSpec) -> Data {
        var plist: [String: Any] = [
            "Label": spec.label,
            "ProgramArguments": spec.programArguments,
            "RunAtLoad": spec.runAtLoad,
            "ThrottleInterval": spec.throttleInterval,
            "ProcessType": spec.processType,
            "WorkingDirectory": spec.workingDirectory.path,
            "StandardOutPath": spec.stdoutPath.path,
            "StandardErrorPath": spec.stderrPath.path
        ]
        if spec.keepAliveOnCrash { plist["KeepAlive"] = ["Crashed": true] }
        if !spec.machServices.isEmpty {
            plist["MachServices"] = Dictionary(uniqueKeysWithValues: spec.machServices.map { ($0, true) })
        }
        if !spec.environment.isEmpty { plist["EnvironmentVariables"] = spec.environment }
        // XML; Foundation writes dictionary keys sorted, so the bytes are stable
        // and "differs" means a real change.
        do {
            return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        } catch {
            preconditionFailure("LaunchAgentPlist: the launchd dictionary failed to serialize: \(error)")
        }
    }
}
