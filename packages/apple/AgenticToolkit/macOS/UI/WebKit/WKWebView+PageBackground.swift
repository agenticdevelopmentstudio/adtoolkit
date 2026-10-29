//
//  WKWebView+PageBackground.swift
//  AgenticToolkit
//

import WebKit

extension WKWebView {

    /// Whether the web view paints its own opaque backdrop under the page.
    ///
    /// WebKit fills the space behind any page that sets no background of its
    /// own with white — `about:blank` included — so a webview with nothing
    /// loaded is a white rectangle in a themed window. Turned off, the view is
    /// transparent there and whatever is behind it shows through.
    ///
    /// Only for a page known to have nothing to show: a real site that sets no
    /// background is written on the assumption of white, and dark text over a
    /// dark theme is unreadable. The browser pane turns it off on its blank
    /// page and back on for everything else.
    ///
    /// SPI: `_setDrawsBackground:` is not API, so it is asked for by name and
    /// skipped where this WebKit has no such selector — the cost of its absence
    /// is the white backdrop this exists to remove, nothing worse.
    func setDrawsPageBackground(_ draws: Bool) {
        let selector = NSSelectorFromString("_setDrawsBackground:")
        guard responds(to: selector) else { return }
        // Through the implementation, as `keepPaintingUnderQuietPresentation()`
        // does, because the parameter is a `BOOL` and `perform(_:with:)` takes
        // an object.
        typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool) -> Void
        let implementation = unsafeBitCast(method(for: selector), to: Setter.self)
        implementation(self, selector, ObjCBool(draws))
    }
}
