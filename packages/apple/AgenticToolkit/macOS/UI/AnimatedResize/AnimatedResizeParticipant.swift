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
    /// An animated resize is starting, and waits for `ready`.
    ///
    /// - Parameters:
    ///   - widthChange: How far the width of the view the animation resizes
    ///     will move, in points — positive to grow. A participant under that
    ///     view, sharing its width with siblings, moves by no more than this,
    ///     and by how much less cannot be known in advance: a split view hands
    ///     a change out by holding priority and by its panes' current sizes,
    ///     and laying the end state out to measure it moves the panes.
    ///   - ready: Called once the view has drawn itself for the animation —
    ///     the animation does not start until every participant has, or until
    ///     `animatedResizeReadinessLimit` has passed.
    func animatedResizeWillBegin(widthChange: CGFloat, ready: @escaping @MainActor () -> Void)

    /// The animation is over and the view has its final frame.
    func animatedResizeDidEnd()
}

/// The longest an animated resize waits for its participants to be ready: a
/// participant that never answers delays it by this, and no more.
public let animatedResizeReadinessLimit: TimeInterval = 0.1

public extension NSView {
    /// Tells every participant at or under this view that an animated resize
    /// is starting, and calls `start` — once — when they are ready for it.
    func beginAnimatedResize(widthChange: CGFloat, start: @escaping @MainActor () -> Void) {
        var participants: [AnimatedResizeParticipant] = []
        forEachAnimatedResizeParticipant { participants.append($0) }
        guard !participants.isEmpty else {
            start()
            return
        }
        var waiting = participants.count
        var started = false
        let startOnce: @MainActor () -> Void = {
            guard !started else { return }
            started = true
            start()
        }
        for participant in participants {
            participant.animatedResizeWillBegin(widthChange: widthChange) {
                waiting -= 1
                if waiting == 0 { startOnce() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + animatedResizeReadinessLimit) {
            MainActor.assumeIsolated { startOnce() }
        }
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
