//
//  LiveResizingWebView.swift
//  AgenticToolkit
//

import WebKit

/// A web view that lets its window move during a live resize instead of
/// holding the window's old image until the page catches up.
///
/// While its window is live-resized, `WKWebView` asks AppKit to hold a resize
/// snapshot (`-[NSWindow _holdResizeSnapshotWithReason:]`) until its web
/// content process commits a frame at the new size. The window then keeps
/// showing its previous image behind the moving edge — a band of WebKit's
/// grey backdrop chasing it, worst on a fast drag — and that is the "fight"
/// a live resize shows. Measured on a window resized 12 points a frame, a
/// plain web view showed the band in twice as many frames as this one. The
/// page still paints a frame or so behind its frame; `FrameHoldingView`
/// covers that by laying the page out wider than it shows while the width
/// moves. Reported upstream as WebKit bug 323132.
///
/// SPI: `_holdWindowResizeSnapshotIfNeeded` is WebKit's private hook, answered
/// here by selector. Where a WebKit has no such method nothing calls this one,
/// and the web view behaves as any other.
public final class LiveResizingWebView: WKWebView {
    @objc(_holdWindowResizeSnapshotIfNeeded)
    private func holdWindowResizeSnapshotIfNeeded() -> Bool { false }
}
