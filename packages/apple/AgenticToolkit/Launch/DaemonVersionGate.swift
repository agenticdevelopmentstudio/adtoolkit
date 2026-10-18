import Foundation
import AgenticToolkitCore

/// A daemon version, optionally ordered across a renumbering.
///
/// A daemon that once reported versions on an old scheme and later switched to
/// a new one would sort wrongly under plain semver (the old numbers can be
/// larger). Passing `legacyMajor` reads every version with that major as
/// *legacy*, ordering it before every non-legacy version. A daemon with no such
/// history passes `nil` and gets plain semver order.
public struct DaemonVersion: Comparable, CustomStringConvertible, Sendable {
    public let isLegacy: Bool
    public let version: SemanticVersion

    public init?(_ string: String, legacyMajor: Int?) {
        guard let version = SemanticVersion(string) else { return nil }
        self.version = version
        isLegacy = legacyMajor.map { version.major == $0 } ?? false
    }

    private init(isLegacy: Bool, version: SemanticVersion) {
        self.isLegacy = isLegacy
        self.version = version
    }

    /// A version from the legacy scheme, whose major is `major`.
    public static func legacy(major: Int, minor: Int, patch: Int) -> Self {
        Self(isLegacy: true, version: SemanticVersion(major: major, minor: minor, patch: patch))
    }

    /// A version from the current scheme.
    public static func current(major: Int, minor: Int, patch: Int) -> Self {
        Self(isLegacy: false, version: SemanticVersion(major: major, minor: minor, patch: patch))
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.isLegacy != rhs.isLegacy ? lhs.isLegacy : lhs.version < rhs.version
    }

    public var description: String { version.description }
}

/// Decides whether an app may run against the daemon it found.
///
/// The app and the daemon ship together but are *deployed* separately, so an
/// app can end up talking to a daemon that predates something it depends on.
/// The test is `>=`, not `==`: a newer daemon is expected to serve an older
/// app, so only an *older* daemon is a fault.
///
/// ``verdict(daemonVersion:)`` **fails open** on anything but a definite
/// "older": an unreachable daemon (it may still be starting) or a version string
/// that cannot be read is "could not tell", not "too old".
/// ``supports(since:daemonVersion:)`` **fails closed**, for calls that must
/// never reach a daemon lacking them.
public struct DaemonVersionGate: Sendable {
    public enum Verdict: Equatable, Sendable {
        /// Run. Covers the daemon being new enough *and* every case where we cannot tell.
        case allowed
        /// The daemon is definitely older than the minimum; carries the version it reported.
        case tooOld(reported: String)
    }

    /// The oldest daemon the app can work against.
    public let minimum: DaemonVersion
    /// See ``DaemonVersion``; nil when the daemon has no renumbering history.
    public let legacyMajor: Int?

    public init(minimum: DaemonVersion, legacyMajor: Int? = nil) {
        self.minimum = minimum
        self.legacyMajor = legacyMajor
    }

    /// Parses a version the daemon reported.
    public func parse(_ string: String) -> DaemonVersion? {
        DaemonVersion(string, legacyMajor: legacyMajor)
    }

    public func verdict(daemonVersion: String?) -> Verdict {
        guard let daemonVersion, let reported = parse(daemonVersion) else { return .allowed }
        return reported < minimum ? .tooOld(reported: daemonVersion) : .allowed
    }

    /// Whether the daemon is known to be at least `since`. Fails closed: nil or
    /// unparseable is false.
    public func supports(since: DaemonVersion, daemonVersion: String?) -> Bool {
        guard let daemonVersion, let reported = parse(daemonVersion) else { return false }
        return reported >= since
    }

    /// Asks the daemon its version (`current`) and, if it is too old, hands the
    /// reported version to `present` on the main actor. Detached rather than
    /// awaited at launch: the version call may retry for several seconds to cover
    /// the login race, and blocking the caller that long stalls its first frame.
    public func enforce(current: @escaping @Sendable () async -> String?,
                        present: @escaping @MainActor @Sendable (_ reported: String,
                                                                 _ minimum: DaemonVersion) -> Void) {
        let minimum = minimum
        Task.detached {
            guard case .tooOld(let reported) = verdict(daemonVersion: await current()) else { return }
            await MainActor.run { present(reported, minimum) }
        }
    }
}
