import AppKit

/// Holds one content view edge to edge, except during an animated resize,
/// when it keeps the content at a single width — the wider of its start and
/// end widths — pinned to the leading edge and clipped at the trailing one.
///
/// The content is resized twice per animation at most, at the start and at
/// the end, instead of on every frame, so content that repaints behind its
/// frame (a `WKWebView`) never shows a gap at the trailing edge: it is always
/// at least as wide as the view, and the view's edge cuts it off.
public final class FrameHoldingView: NSView, AnimatedResizeParticipant {
    public let content: NSView

    private var trailingToEdge: NSLayoutConstraint?
    private var heldWidth: NSLayoutConstraint?

    public init(content: NSView) {
        self.content = content
        super.init(frame: .zero)
        clipsToBounds = true
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        let trailing = content.trailingAnchor.constraint(equalTo: trailingAnchor)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            trailing
        ])
        trailingToEdge = trailing
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func animatedResizeWillBegin(expectedWidthScale: CGFloat) {
        guard heldWidth == nil, let trailingToEdge else { return }
        let start = bounds.width
        // A couple of points over, so a slightly short estimate still never
        // uncovers the background at the very end of a widening.
        let width = ceil(max(start, start * expectedWidthScale)) + 2
        trailingToEdge.isActive = false
        let held = content.widthAnchor.constraint(equalToConstant: width)
        held.isActive = true
        heldWidth = held
    }

    public func animatedResizeDidEnd() {
        guard let held = heldWidth else { return }
        held.isActive = false
        heldWidth = nil
        trailingToEdge?.isActive = true
    }
}
