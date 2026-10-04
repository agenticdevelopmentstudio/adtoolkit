// iOS performs no usage observation or capture at all (c9): there is no
// Accessibility API, no `NSWorkspace`, and no `AgenticToolkitCoreMacOS` on
// iOS to observe with. These no-op adapters exist only so `AgenticToolkitActivity-iOS`
// type-checks against the same `FocusSource`/`WindowLifecycleSource`/
// `IdleSource`/`PowerSource` protocols the macOS adapters conform to (c2);
// nothing on iOS constructs `UsageCollector` (that type itself is
// `#if os(macOS)`-only — see `UsageCollector.swift`), so these are inert.
#if os(iOS)
import Foundation

@MainActor
public final class NoOpFocusSource: FocusSource {
    public var onFocus: ((WindowFocus) -> Void)?
    public init() {}
    public func start() {}
    public func stop() {}
    public func poll() {}
}

@MainActor
public final class NoOpWindowLifecycleSource: WindowLifecycleSource {
    public var onEvent: ((WindowLifecycleKind, AppInfo, UInt32, String) -> Void)?
    public var onTitleChange: (() -> Void)?
    public init() {}
    public func start() {}
    public func stop() {}
}

@MainActor
public final class NoOpIdleSource: IdleSource {
    public var onIdle: (() -> Void)?
    public var onActive: (() -> Void)?
    public init() {}
    public func start() {}
    public func stop() {}
}

@MainActor
public final class NoOpPowerSource: PowerSource {
    public var onLock: (() -> Void)?
    public var onSleep: (() -> Void)?
    public var onAppQuit: ((Int32) -> Void)?
    public var onResume: (() -> Void)?
    public init() {}
    public func start() {}
    public func stop() {}
}
#endif
