import AppKit

/// The Browser pane the user (or a model) last put their attention on.
///
/// The default pane a model drives when it names none is "the most recently
/// focused Browser pane", and the window's active pane cannot answer that:
/// while the user types in a terminal beside a browser, the active pane is the
/// terminal. So each Browser pane notes itself here when it appears, when its
/// web view becomes first responder, and when a drive starts on it, and the
/// app's pane directory asks this record first.
///
/// Weak, so a closed pane is forgotten without anyone telling this record.
@MainActor
public final class BrowserPaneFocus {
    public static let shared = BrowserPaneFocus()

    public private(set) weak var lastFocused: BrowserPaneViewController?

    public init() {}

    public func note(_ pane: BrowserPaneViewController) {
        lastFocused = pane
    }
}
