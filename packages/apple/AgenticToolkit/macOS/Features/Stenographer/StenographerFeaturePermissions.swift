import AgenticToolkitPermissions

/// The grants the Stenographer-fed features need from the app that hosts them.
///
/// Only Automation, and only for the two terminals: the Conversations window
/// types a reply, and the AI Oversight window a finding, into the session's
/// terminal through `TerminalTextInjector`, and nothing else the four windows
/// do touches a TCC-guarded resource. A host merges the pair into its own set
/// with ``adding(to:)`` and hands the result to its permissions pane and its
/// first-launch walkthrough, so the user is asked once, in one place.
public enum StenographerFeaturePermissions {

    public static let all: [Permission] = [
        .automation(targetBundleID: "com.googlecode.iterm2"),
        .automation(targetBundleID: "com.apple.Terminal")
    ]

    /// The host's own set, in its order, with the features' grants appended —
    /// and no grant listed twice, so a host already asking for iTerm2 asks once.
    public static func adding(to host: [Permission]) -> [Permission] {
        var combined = host
        for permission in all where !combined.contains(permission) {
            combined.append(permission)
        }
        return combined
    }
}
