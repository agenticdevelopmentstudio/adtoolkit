import Foundation
@testable import AgenticToolkitActivity

@MainActor
final class FakeFocusSource: FocusSource {
    var onFocus: ((WindowFocus) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var pollCount = 0

    /// What `poll()` re-emits, mirroring `FrontmostFocusAdapter.poll()`, which
    /// re-reads the frontmost window and emits it. `nil` (the default) keeps
    /// `poll()` silent, as it was before this property existed.
    var current: WindowFocus?

    /// Emits `current`, as `FrontmostFocusAdapter.start()` does: it registers
    /// its observer and then calls `emit()` immediately, so what the user is
    /// already looking at is recorded rather than waiting for the next app
    /// switch. A fake that stayed silent here hid that opening event from
    /// every test, including the dedupe it feeds.
    func start() {
        startCount += 1
        if let current { onFocus?(current) }
    }
    func stop() { stopCount += 1 }
    func poll() {
        pollCount += 1
        if let current { onFocus?(current) }
    }
    func emit(_ f: WindowFocus) { onFocus?(f) }
}
@MainActor
final class FakeWindowSource: WindowLifecycleSource {
    var onEvent: ((WindowLifecycleKind, AppInfo, UInt32, String) -> Void)?
    var onTitleChange: (() -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func emit(_ k: WindowLifecycleKind, _ a: AppInfo, _ w: UInt32, _ t: String) { onEvent?(k, a, w, t) }

    /// The real adapter fires `onEvent(.titleChanged, …)` and `onTitleChange`
    /// together, so the fake does too.
    func emitTitleChange(_ a: AppInfo = AppInfo(bundleID: "", name: "", pid: 0),
                         _ w: UInt32 = 1, _ t: String = "new title") {
        onEvent?(.titleChanged, a, w, t)
        onTitleChange?()
    }
}
@MainActor
final class FakeIdleSource: IdleSource {
    var onIdle: (() -> Void)?; var onActive: (() -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
}
@MainActor
final class FakePowerSource: PowerSource {
    var onLock: (() -> Void)?; var onSleep: (() -> Void)?; var onAppQuit: ((Int32) -> Void)?
    var onResume: (() -> Void)?
    func start() {}; func stop() {}
}
