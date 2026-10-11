//
//  WKWebView+QuietPresentation.swift
//  AgenticToolkit
//

import WebKit
import AgenticToolkitCoreMacOS

extension WKWebView {

    /// Keeps the page painting while the app's windows are sunk behind the
    /// desktop picture.
    ///
    /// WebKit stops drawing into a window the window server reports occluded —
    /// it logs `window occluded 1`, `isViewVisible()` goes false, and what a
    /// screenshot picks up is whatever was last painted, which for a page that
    /// was never on screen is nothing at all. Quiet presentation sinks every
    /// window below the desktop *on purpose*, so under automation every webview
    /// is occluded by definition. JavaScript keeps running throughout — the
    /// page loads, scripts run, state persists — which is why this stayed
    /// invisible until something had to be photographed.
    ///
    /// One helper for every `WKWebView` the toolkit puts in a pane — the
    /// extension webview panel and the browser pane both call it — so the SPI
    /// name and the debug-only guard are spelled once (`dry`).
    ///
    /// Debug-only, and SPI: `_setWindowOcclusionDetectionEnabled:` is not API,
    /// so it is asked for by name and skipped where this WebKit has no such
    /// selector. A shipping binary does not carry it at all — there is no
    /// automation driving a released app, and a real user's occluded window
    /// *should* stop painting rather than burn the battery drawing frames
    /// nobody can see.
    func keepPaintingUnderQuietPresentation() {
        #if DEBUG
        guard QuietWindowPresentation.isEnabled else { return }
        let selector = NSSelectorFromString("_setWindowOcclusionDetectionEnabled:")
        guard responds(to: selector) else { return }
        // Called through the implementation rather than `perform(_:with:)`,
        // which takes an object: the parameter is a `BOOL`, and the only way to
        // pass a false one through `perform` is a nil argument that reads as
        // zero by accident (`explicit-over-implicit`).
        typealias Setter = @convention(c) (AnyObject, Selector, ObjCBool) -> Void
        let implementation = unsafeBitCast(method(for: selector), to: Setter.self)
        implementation(self, selector, false)
        #endif
    }
}
