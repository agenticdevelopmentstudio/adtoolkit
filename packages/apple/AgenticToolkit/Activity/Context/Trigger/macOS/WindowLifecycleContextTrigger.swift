#if os(macOS)
import Foundation

/// Emits a `window` event when any window is created, destroyed or retitled.
///
/// Named `WindowLifecycleContextTrigger`, not `WindowTrigger`, because
/// `WindowLifecycleAdapter`/`WindowLifecycleSource` already own that vocabulary
/// and this is the context-tracking face of them.
@MainActor
public final class WindowLifecycleContextTrigger: ContextTrigger {
    public let kind: ContextEventKind = .window
    public let requiredPermission: ContextPermission = .accessibility
    public var onEvent: ((ContextEventDetail, Date) -> Void)?

    private let source: any WindowLifecycleSource
    private let now: () -> Date
    private var isRunning = false

    public init(source: any WindowLifecycleSource = WindowLifecycleAdapter(),
                now: @escaping () -> Date = { Date() }) {
        self.source = source
        self.now = now
    }

    public func start() throws {
        guard !isRunning else { return }
        isRunning = true
        source.onEvent = { [weak self] kind, app, windowID, title in
            self?.emit(kind, app, windowID, title)
        }
        source.start()
    }

    /// Guarded by `isRunning`, symmetrically with `start()`: `source` may be a
    /// `SharedWindowLifecycleSource` whose start/stop calls are counted, and
    /// an unbalanced `stop()` here would switch off an observation
    /// `AppFocusTrigger` is still using for its title-change nudge (I-3).
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        source.onEvent = nil
        source.stop()
    }

    private func emit(_ lifecycle: WindowLifecycleKind, _ app: AppInfo,
                      _ windowID: UInt32, _ title: String) {
        guard isRunning else { return }
        onEvent?(.window(WindowDetail(
            change: Self.change(for: lifecycle),
            bundleID: app.bundleID, appName: app.name, pid: app.pid,
            windowID: windowID,
            windowTitle: title.isEmpty ? nil : title)), now())
    }

    private static func change(for kind: WindowLifecycleKind) -> WindowChange {
        switch kind {
        case .created:      return .created
        case .destroyed:    return .destroyed
        case .titleChanged: return .titleChanged
        }
    }
}
#endif
