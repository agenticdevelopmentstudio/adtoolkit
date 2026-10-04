// AppKit/ApplicationServices observation — macOS only (c2). iOS compiles
// `NoOpObservationAdapters.swift` instead.
#if os(macOS)
import AppKit
import ApplicationServices
import AgenticToolkitMacOS

/// Standard private SPI for resolving the `CGWindowID` of an `AXUIElement`
/// window. There is no public Accessibility API for this; `_AXUIElementGetWindow`
/// is the widely-used, stable SPI (declared via `@_silgen_name` since it isn't
/// exposed in the public headers). Falls back to windowID 0 on error.
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

/// Observes app-activation via `NSWorkspace` and reads the frontmost app's
/// focused-window title/document via the Accessibility C API.
///
/// `NSWorkspace.didActivateApplicationNotification` is delivered on the main
/// thread, so the `@objc` selector is declared `nonisolated` and its body
/// runs inside `MainActor.assumeIsolated` — see `WindowLifecycleAdapter` for
/// the shared rationale.
// Public, and its `FocusSource` witnesses are public too: `olylod`
// constructs this directly and hands it to `UsageCollector`'s public
// initializer as a `FocusSource` — a public type's public conformance to a
// public protocol requires its witnesses be public as well.
@MainActor
public final class FrontmostFocusAdapter: FocusSource {
    public var onFocus: ((WindowFocus) -> Void)?
    /// `false` is the app-only mode for a process without the Accessibility
    /// grant: an `AXIsProcessTrusted`-less AX call stalls tccd, so in that mode
    /// no AX or Apple Events call is made at all — no window read, no
    /// ``FrontmostElementObserver``, no terminal working-directory read. The
    /// emitted ``WindowFocus`` then carries windowID 0, an empty title and no
    /// document path or URL.
    public let readsWindows: Bool
    /// The window read — AX in production. Injected so a test can prove the
    /// app-only mode never calls it.
    typealias WindowReader = (pid_t, String) -> WindowReading
    private let windowReader: WindowReader
    private let apps: any RunningAppsProvider
    /// Held across focus changes rather than made per read: it remembers this
    /// process's Automation answer, so the consent dialog is raised once and
    /// a denial costs nothing thereafter. See ``TerminalWorkingDirectoryReader``.
    private let terminals = TerminalWorkingDirectoryReader()
    /// Catches focus moving *inside* the frontmost app — another of its
    /// windows, another terminal tab — which no app activation announces and
    /// which was previously not observed at all. See
    /// ``FrontmostElementObserver``.
    private let elements = FrontmostElementObserver()

    public init(readsWindows: Bool = true) {
        self.readsWindows = readsWindows
        self.windowReader = { Self.focusedWindow(pid: $0, bundleID: $1) }
        self.apps = RealRunningAppsProvider()
    }

    init(readsWindows: Bool, windowReader: @escaping WindowReader,
         apps: any RunningAppsProvider) {
        self.readsWindows = readsWindows
        self.windowReader = windowReader
        self.apps = apps
    }

    public func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(activated),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
        if readsWindows {
            elements.onChange = { [weak self] in self?.emit() }
            elements.start()
        }
        emit()
    }
    public func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        if readsWindows {
            elements.onChange = nil
            elements.stop()
        }
    }

    /// Re-emits the current focus on demand: wired to idle/lock/sleep resume
    /// in `UsageCollector.start()`, and to `WindowLifecycleSource
    /// .onTitleChange` by both pipelines so a retitle (a browser tab switch,
    /// say) produces a fresh focus reading without waiting for the next
    /// app activation.
    public func poll() { emit() }

    @objc private nonisolated func activated() {
        MainActor.assumeIsolated { self.emit() }
    }

    /// Reads the current frontmost app/window and hands it to `onFocus`.
    /// Public because it is also this type's `poll()` — see that method for
    /// who asks for a re-read and why.
    public func emit() {
        guard let a = apps.frontmostApplication else { return }
        let pid = a.processIdentifier
        let bundleID = a.bundleIdentifier ?? "unknown"
        let reading = readsWindows ? windowReader(pid, bundleID) : WindowReading()
        // A terminal answers `kAXDocumentAttribute` with nothing, so its
        // working directory is asked for over Apple Events instead — but only
        // once Accessibility has had its turn, so an app that really does have
        // a document is never charged the round-trip.
        let documentPath = readsWindows
            ? (reading.documentPath ?? terminals.workingDirectory(forBundleID: bundleID))
            : nil
        onFocus?(WindowFocus(app: AppInfo(bundleID: bundleID,
            name: a.localizedName ?? "unknown", pid: pid), windowID: reading.windowID,
            title: reading.title, documentPath: documentPath, url: reading.url))
    }

    struct WindowReading: Equatable {
        var windowID: UInt32 = 0
        var title: String = ""
        var documentPath: String?
        var url: String?
    }

    /// `bundleID` is passed in rather than re-derived from the pid because it
    /// selects how the address bar is read — see ``BrowserAddressReader``.
    nonisolated static func focusedWindow(pid: pid_t, bundleID: String) -> WindowReading {
        let appEl = AXUIElementCreateApplication(pid)
        // Bound the AX messaging round-trip: a hung/unresponsive frontmost
        // app must not stall the main run loop indefinitely.
        AXUIElementSetMessagingTimeout(appEl, 1.0)
        var winRef: CFTypeRef?
        // Verify the returned CF type before casting: a soft return here beats
        // an `as!` trap crashing the daemon's main thread if a frontmost app's
        // AX server ever answers kAXFocusedWindowAttribute with an off-type value.
        guard AXUIElementCopyAttributeValue(appEl, kAXFocusedWindowAttribute as CFString, &winRef) == .success,
              let winRef, CFGetTypeID(winRef) == AXUIElementGetTypeID() else { return WindowReading() }
        let w = winRef as! AXUIElement   // safe: type-id verified above
        var tRef: CFTypeRef?; AXUIElementCopyAttributeValue(w, kAXTitleAttribute as CFString, &tRef)
        var dRef: CFTypeRef?; AXUIElementCopyAttributeValue(w, kAXDocumentAttribute as CFString, &dRef)
        var wid: CGWindowID = 0
        _ = _AXUIElementGetWindow(w, &wid)

        // A window that names no document may still be showing one: some apps
        // hang it on the focused element instead. Asked for only in that case,
        // so an app that answered on the window pays nothing.
        let rawDocument = (dRef as? String) ?? focusedElementDocument(appEl)

        // `kAXDocumentAttribute` is answered with a file URL by document apps
        // and with a page URL by Chromium browsers; `WindowAddress` is what
        // decides which arrived. Only when it yields no URL is the subtree
        // walked, so Chrome and Brave never pay for the walk and neither does
        // any app that is not a browser at all.
        let address = WindowAddress(rawDocument: rawDocument)
        let url = address?.urlString
            ?? BrowserAddressReader.address(inWindow: w, bundleID: bundleID)
        return WindowReading(windowID: wid, title: (tRef as? String) ?? "",
                             documentPath: address?.filePath, url: url)
    }

    /// The document named by the app's *focused element*, for apps that hang it
    /// there rather than on the window.
    ///
    /// iTerm2 is the case this exists for. Its window answers
    /// `kAXDocumentAttribute` with nothing, which is what sent this adapter to
    /// Apple Events; but the focused session's text area answers with the
    /// session's working directory, as `file://user@host/path`. `WindowAddress`
    /// already reduces that to the local path, because `URL.path` drops the
    /// authority.
    ///
    /// This is what makes a terminal tab or split-pane switch legible. Such a
    /// switch changes no window, no window id, and — measured over six
    /// switches — the title only once; the working directory is the one thing
    /// that reliably differs, so without it the switch dedupes away against the
    /// previous reading and no row is ever written. Reading it through
    /// Accessibility rather than Apple Events also means it needs no Automation
    /// consent, so the common case raises no second permission prompt at all.
    ///
    /// Two tabs open on the *same* directory still collapse into one reading.
    /// That is the intended answer: the directory is the context being
    /// recorded, and two views of one project are one context.
    nonisolated static func focusedElementDocument(_ appElement: AXUIElement) -> String? {
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString,
                                            &focused) == .success,
              let focused, CFGetTypeID(focused) == AXUIElementGetTypeID()
        else { return nil }
        var document: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused as! AXUIElement,   // safe: type-id verified
                                            kAXDocumentAttribute as CFString,
                                            &document) == .success
        else { return nil }
        return document as? String
    }
}
#endif
