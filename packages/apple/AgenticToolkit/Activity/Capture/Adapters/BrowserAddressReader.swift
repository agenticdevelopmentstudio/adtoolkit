// Accessibility reading of a browser's address bar — macOS only (c2).
#if os(macOS)
import ApplicationServices
import Foundation

/// Reads the address a browser window is showing, for the browsers that do
/// not answer `kAXDocumentAttribute`.
///
/// Chromium-based browsers (Chrome, Brave, Edge, Arc, Vivaldi) already return
/// the full page URL from `kAXDocumentAttribute` on the focused window, so
/// they are absent from this file: ``FrontmostFocusAdapter`` gets their URL
/// for free and ``WindowAddress`` classifies it. Safari and Firefox both
/// answer that attribute with `kAXErrorNoValue` (-25212), and for them the
/// address exists only as the value of a control in the toolbar. Finding it
/// means walking the window's subtree.
///
/// **What this costs the reader.** Safari and Firefox render the address the
/// way a person reads it, not the way a machine stores it: Firefox in
/// particular hides the scheme, so a page recorded here can read
/// `example.org/page` where Brave records `https://example.org/page`. The
/// value is stored as reported rather than repaired, because guessing `https`
/// onto an address that was served over `http` would record something that
/// never happened.
///
/// No Automation (Apple Events) permission is involved. Everything here runs
/// on the Accessibility grant the daemon already holds.
enum BrowserAddressReader {
    /// The browsers whose address bar has to be read out of the view tree,
    /// and the shape of the control that holds it.
    enum Family {
        /// Safari names its address bar, so it can be found by identifier —
        /// the one anchor here that is neither localized nor positional.
        case safari
        /// Firefox exposes no identifier and localizes the description, so
        /// only the role is left to match on.
        case firefox

        static func forBundleID(_ bundleID: String) -> Family? {
            switch bundleID {
            case "com.apple.Safari", "com.apple.SafariTechnologyPreview":
                return .safari
            case "org.mozilla.firefox", "org.mozilla.firefoxdeveloperedition",
                 "org.mozilla.nightly":
                return .firefox
            default:
                return nil
            }
        }
    }

    /// Safari's own identifier for the combined address and search field.
    /// Unchanged across every Safari this was measured against, and not
    /// user-visible, so it does not move with the system language.
    private static let safariAddressFieldID = "WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD"

    /// How deep to walk before giving up. The address bar sits within three
    /// or four levels of the window in both browsers; the bound is what stops
    /// a focus change from descending into a whole rendered page, which is
    /// unbounded and would be read on the main thread.
    private static let maxDepth = 6

    /// The address shown by `window`, or `nil` if this app is not a browser
    /// this reader knows, or the bar could not be found.
    /// `window` must already be bounded; every child the walk reads is
    /// bounded by `ax` before its first read.
    static func address(inWindow window: AXUIElement, bundleID: String, ax: BoundedAX = .live) -> String? {
        guard let family = Family.forBundleID(bundleID) else { return nil }
        return find(in: window, family: family, depth: 0, ax: ax)
    }

    private static func find(in element: AXUIElement, family: Family, depth: Int, ax: BoundedAX) -> String? {
        if depth > maxDepth { return nil }
        if let value = address(of: element, family: family, ax: ax) { return value }
        for child in ax.children(element) {
            if let value = find(in: child, family: family, depth: depth + 1, ax: ax) { return value }
        }
        return nil
    }

    /// Whether this one element *is* the address bar, and what it holds.
    private static func address(of element: AXUIElement, family: Family, ax: BoundedAX) -> String? {
        func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
            let (error, value) = ax.attribute(element, name)
            return error == .success ? value : nil
        }
        guard let role = attribute(element, kAXRoleAttribute) as? String else { return nil }
        switch family {
        case .safari:
            guard role == kAXTextFieldRole as String,
                  attribute(element, "AXIdentifier") as? String == safariAddressFieldID
            else { return nil }
        case .firefox:
            // Role alone, so anything else shaped like a combo box in the
            // toolbar could match first. The value check below is what keeps
            // that from recording a search box's contents as a URL.
            guard role == kAXComboBoxRole as String else { return nil }
        }
        guard let value = attribute(element, kAXValueAttribute) as? String,
              looksLikeAnAddress(value)
        else { return nil }
        return value
    }

    /// A weak test, deliberately: Firefox strips the scheme, so requiring one
    /// would reject every Firefox reading. An explicit scheme passes; failing
    /// that, a dot with something on each side is what separates
    /// `example.org/page` from a half-typed search term.
    ///
    /// Scheme-less addresses without a dot — `localhost:3000`, `about:blank` —
    /// are rejected. That is the price of matching Firefox's address bar on
    /// its role alone: the same test has to reject whatever else in the
    /// toolbar happens to be a combo box, and letting arbitrary short strings
    /// through would record a search term as a visited page.
    static func looksLikeAnAddress(_ value: String) -> Bool {
        if value.contains("://") { return true }
        guard let dot = value.firstIndex(of: "."), dot != value.startIndex else { return false }
        return value.index(after: dot) != value.endIndex && !value.hasPrefix(" ")
    }
}
#endif
