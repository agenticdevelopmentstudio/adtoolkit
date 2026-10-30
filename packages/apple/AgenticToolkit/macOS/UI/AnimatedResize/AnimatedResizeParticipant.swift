import AppKit

/// A view that wants warning before a short scripted animation resizes it —
/// a shelf sliding in beside it, say — and word when it is over.
///
/// For views whose content cannot repaint in step with their frame. A
/// `WKWebView` paints out of process, a frame or more behind its own frame, so
/// resized on every frame of an animation its page trails its edge for the
/// whole of it. Told the size is about to move, such a view can hold its
/// content still for the length of the animation and resize it once at the
/// end. `FrameHoldingView` is the ready-made one.
@MainActor
public protocol AnimatedResizeParticipant: AnyObject {
    /// An animated resize is starting.
    ///
    /// - Parameter expectedWidthScale: The view's width at the end of the
    ///   animation over its width now, as near as the animator can say.
    func animatedResizeWillBegin(expectedWidthScale: CGFloat)

    /// The animation is over and the view has its final frame.
    func animatedResizeDidEnd()
}

public extension NSView {
    /// Tells every participant at or under this view that an animated resize
    /// is starting.
    func beginAnimatedResize(expectedWidthScale: CGFloat) {
        forEachAnimatedResizeParticipant { $0.animatedResizeWillBegin(expectedWidthScale: expectedWidthScale) }
    }

    /// Tells every participant at or under this view that the animated resize
    /// is over.
    func endAnimatedResize() {
        forEachAnimatedResizeParticipant { $0.animatedResizeDidEnd() }
    }

    private func forEachAnimatedResizeParticipant(_ body: (AnimatedResizeParticipant) -> Void) {
        if let participant = self as? AnimatedResizeParticipant { body(participant) }
        subviews.forEach { $0.forEachAnimatedResizeParticipant(body) }
    }
}
