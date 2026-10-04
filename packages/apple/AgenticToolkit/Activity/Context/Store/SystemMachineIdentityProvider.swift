// IOKit is macOS-only; iOS/Android/Windows each get their own provider when
// those clients are built. The protocol above stays cross-platform.
#if os(macOS)
import Foundation
import IOKit

public struct SystemMachineIdentityProvider: MachineIdentityProviding {
    private let id: UUID

    /// `id` is the caller's persisted machine UUID (minted once and stored in
    /// the settings table), not a fresh one per launch.
    public init(id: UUID) { self.id = id }

    public func currentMachine() -> MachineDescriptor {
        MachineDescriptor(
            id: id,
            platform: .macOS,
            nativeID: Self.ioPlatformUUID(),
            nativeIDKind: .ioPlatformUUID,
            hostname: ProcessInfo.processInfo.hostName,
            model: Self.sysctlString("hw.model"),
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString)
    }

    private static func ioPlatformUUID() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        let value = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString,
                                                    kCFAllocatorDefault, 0)
        return value?.takeRetainedValue() as? String
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        // `sysctlbyname` writes a NUL-terminated string and reports the length
        // including that terminator; `String(decoding:)` would keep it as a
        // U+0000 scalar, so drop it before decoding.
        return String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
}
#endif
