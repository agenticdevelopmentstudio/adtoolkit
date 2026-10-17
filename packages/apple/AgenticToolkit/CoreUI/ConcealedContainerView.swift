import AppKit

/// A view whose contents nothing outside the app may read: the accessibility
/// API, a screen reader, an AppleScript view dump, or a screen capture.
///
/// - **Accessibility.** The container is not an element and has no children,
///   so the subtree under it simply does not exist to an AX client —
///   VoiceOver and `AXUIElement` walks alike. A hit test landing inside it
///   resolves to the nearest element *above* it, so nothing below is ever
///   named. A view placed inside should not be an element either, or a hit
///   test can still land on it.
/// - **Scripting.** A script command that walks views must stop at one of
///   these. Within this framework's reach, `isConcealed(_:)` is the check;
///   a framework beneath it (AgenticToolkitScripting is AppKit-only) checks
///   for the ``ConcealsContents`` protocol by its Objective-C name instead.
/// - **Screen capture.** While ``isRevealed`` is true and the view is in a
///   window, that window's `sharingType` is `.none`, which blanks it for
///   screenshots, screen recording and screen sharing. The window goes back
///   to `.readOnly` when no concealed view in it is revealed any longer.
open class ConcealedContainerView: NSView, ConcealsContents {

    /// Whether the contents are on screen. The owner sets this when its
    /// privacy screen comes down and goes back up.
    public var isRevealed = false {
        didSet { updateWindowSharing(window) }
    }

    /// Whether `view` is inside a concealed container — the test a view walk
    /// makes before reading anything off a view.
    public static func isConcealed(_ view: NSView) -> Bool {
        var current: NSView? = view
        while let candidate = current {
            if candidate is ConcealedContainerView { return true }
            current = candidate.superview
        }
        return false
    }

    open override func isAccessibilityElement() -> Bool { false }
    open override func accessibilityChildren() -> [Any]? { [] }
    open override func accessibilityChildrenInNavigationOrder() -> [any NSAccessibilityElementProtocol]? { [] }
    open override func accessibilityVisibleChildren() -> [Any]? { [] }
    open override func accessibilityHitTest(_ point: NSPoint) -> Any? {
        // AppKit asks on the main thread; the override is nonisolated.
        MainActor.assumeIsolated { superview.flatMap { NSAccessibility.unignoredAncestor(of: $0) } }
    }

    open override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        // Leaving a window takes this view's claim on it along.
        if let oldWindow = window, oldWindow !== newWindow {
            updateWindowSharing(oldWindow, excludingSelf: true)
        }
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateWindowSharing(window)
    }

    private func updateWindowSharing(_ window: NSWindow?, excludingSelf: Bool = false) {
        guard let window, let content = window.contentView else { return }
        let anyRevealed = Self.revealedContainers(in: content).contains { !(excludingSelf && $0 === self) }
        window.sharingType = anyRevealed ? .none : .readOnly
    }

    private static func revealedContainers(in view: NSView) -> [ConcealedContainerView] {
        if let concealed = view as? ConcealedContainerView {
            return concealed.isRevealed ? [concealed] : []
        }
        return view.subviews.flatMap(revealedContainers(in:))
    }
}

/// A view whose subviews nothing outside the app may read.
///
/// Its Objective-C name, `ATKConcealsContents`, is the contract: a framework
/// that cannot import this one asks the runtime for the protocol by that
/// name and stops at any view conforming to it. Renaming it breaks them
/// silently, so the name is fixed.
@objc(ATKConcealsContents)
public protocol ConcealsContents {}
