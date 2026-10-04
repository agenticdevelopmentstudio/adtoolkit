import Foundation

/// The platform a machine runs, stored verbatim in `machine.platform`.
/// These raw values are the cross-platform schema contract — an Android or
/// Windows client writes the same strings — so they never track Swift casing.
public enum MachinePlatform: String, Sendable, CaseIterable, Codable {
    case macOS = "macos"
    case iOS = "ios"
    case android = "android"
    case windows = "windows"
}

/// Which OS-provided identifier `MachineDescriptor.nativeID` came from.
/// Recorded alongside the value because the identifiers are not comparable
/// across kinds and have different reset semantics (an `idfv` resets when the
/// user removes every app from the vendor; an `ioPlatformUUID` does not).
public enum MachineNativeIDKind: String, Sendable, Codable {
    case ioPlatformUUID = "ioplatformuuid"
    case idfv = "idfv"
    case androidID = "android_id"
    case machineGUID = "machineguid"
}

/// One device in the user's fleet. `id` is OUR minted UUID and is what event
/// rows reference; `nativeID` is only a hint for recognising the same physical
/// device again. A native id that resets simply produces a new descriptor with
/// a new `id`, which the user can later join via the `machine_link` table —
/// joining never rewrites event rows.
public struct MachineDescriptor: Sendable, Equatable, Codable {
    public let id: UUID
    public let platform: MachinePlatform
    public let nativeID: String?
    public let nativeIDKind: MachineNativeIDKind?
    public let hostname: String?
    public let model: String?
    public let osVersion: String?

    public init(id: UUID, platform: MachinePlatform, nativeID: String?,
                nativeIDKind: MachineNativeIDKind?, hostname: String?,
                model: String?, osVersion: String?) {
        self.id = id
        self.platform = platform
        self.nativeID = nativeID
        self.nativeIDKind = nativeIDKind
        self.hostname = hostname
        self.model = model
        self.osVersion = osVersion
    }
}

/// Supplies the descriptor for the machine this process runs on. A protocol so
/// tests can inject a fixed machine and so Android/Windows ports can supply
/// their own without touching `ContextStore`.
public protocol MachineIdentityProviding: Sendable {
    func currentMachine() -> MachineDescriptor
}
