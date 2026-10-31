import AppKit

/// Holds one content view edge to edge, except while its width is changing,
/// when it can keep the content wider than the view — pinned to the leading
/// edge and clipped at the trailing one — so content that repaints behind its
/// frame (a `WKWebView`) never shows a gap at the trailing edge.
///
/// Two kinds of change are covered:
///
/// - **An animated resize** (`AnimatedResizeParticipant`). Narrowing, the
///   content is held at its start width and resized once, at the end — its
///   old drawing is wider than the view throughout. Growing, it follows the
///   view's width plus a lead, never past the start width plus all of the
///   growth announced: held still instead, a page was laid out at a width its
///   pane never reached, and jumped back at the end. Either way the animation
///   waits until the content has drawn for it.
/// - **A run of small steps** — a divider drag, a live window resize — only
///   with `leadsWidthChanges`: the content follows the view's width plus a
///   lead, so the strip a web view has not yet painted lies past the clip. The
///   lead grows with the fastest step seen, because a web view trails by a few
///   frames whatever the speed, and the content goes back to the view's own
///   width once the steps stop. Off by default, because content that reflows
///   to its width — a terminal's columns, an editor's wrapping — would reflow
///   twice for every drag.
public final class FrameHoldingView: NSView, AnimatedResizeParticipant {
    public let content: NSView
    private let leadsWidthChanges: Bool

    private var trailingToEdge: NSLayoutConstraint?
    /// The content's width constraints while an animated resize runs; empty
    /// when none is.
    private var animating: [NSLayoutConstraint] = []

    /// `content.width == width + lead` during a run of steps.
    private var leading: NSLayoutConstraint?
    private var lastWidth: CGFloat = 0

    /// Frames a web view trails its frame by, and some to spare: the lead is
    /// this many of the fastest step.
    private static let framesOfLag: CGFloat = 5
    private static let maximumLead: CGFloat = 160
    /// A step wider than this is one change — a pane opened or closed — not a
    /// drag, and is left to the content to follow.
    private static let largestStep: CGFloat = 120
    /// How long the width must stay still before the run of steps is over.
    private static let settleDelay: TimeInterval = 0.3
    /// The lead while an animated resize grows the view: its steps are larger
    /// than a drag's, as much as a seventh of the change in one frame.
    private static let animatedLead: CGFloat = 200

    public init(content: NSView, leadsWidthChanges: Bool = false) {
        self.content = content
        self.leadsWidthChanges = leadsWidthChanges
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

    public override func layout() {
        followWidthChange()
        super.layout()
    }

    // MARK: - Runs of small steps

    /// A live resize announces itself before its first step, so the lead can
    /// be in place — and painted — before the edge moves at all; caught only by
    /// its first step, that step's own width shows unpainted for a frame.
    public override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        guard leadsWidthChanges, animating.isEmpty, leading == nil, window != nil else { return }
        startLeading(by: Self.maximumLead)
    }

    public override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        guard leading != nil else { return }
        settleLater()
    }

    private func followWidthChange() {
        let width = bounds.width
        let step = width - lastWidth
        let previous = lastWidth
        lastWidth = width
        guard leadsWidthChanges, animating.isEmpty, window != nil, previous > 0, step != 0 else { return }
        if let leading {
            if step > 0 {
                leading.constant = min(Self.maximumLead, max(leading.constant, step * Self.framesOfLag))
            }
        } else {
            guard step > 0, step <= Self.largestStep else { return }
            startLeading(by: min(Self.maximumLead, step * Self.framesOfLag))
        }
        settleLater()
    }

    private func startLeading(by lead: CGFloat) {
        trailingToEdge?.isActive = false
        let constraint = content.widthAnchor.constraint(equalTo: widthAnchor, constant: lead)
        constraint.isActive = true
        leading = constraint
    }

    private func settleLater() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(settle), object: nil)
        perform(#selector(settle), with: nil, afterDelay: Self.settleDelay)
    }

    @objc private func settle() {
        guard let leading else { return }
        leading.isActive = false
        self.leading = nil
        if animating.isEmpty { trailingToEdge?.isActive = true }
    }

    // MARK: - AnimatedResizeParticipant

    public func animatedResizeWillBegin(widthChange: CGFloat, ready: @escaping @MainActor () -> Void) {
        guard animating.isEmpty, let trailingToEdge else {
            ready()
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(settle), object: nil)
        leading?.isActive = false
        leading = nil
        trailingToEdge.isActive = false
        // Every width below required, under a floor of the view's own width,
        // so the content still covers the view whatever happens to it. And
        // below the window's own size-holding priority: held any higher, the
        // floor was met by shrinking the window to the content instead of
        // stretching the content, and every slide left the window narrower.
        let floor = content.widthAnchor.constraint(greaterThanOrEqualTo: widthAnchor)
        if widthChange > 0 {
            // How much of the change this view gets cannot be known: a split
            // view hands it out by holding priority and its panes' current
            // sizes. All of it is the most, so the lead never takes the
            // content past that.
            let lead = content.widthAnchor.constraint(
                equalTo: widthAnchor, constant: min(widthChange, Self.animatedLead))
            lead.priority = .defaultLow
            let ceiling = content.widthAnchor.constraint(
                lessThanOrEqualToConstant: ceil(bounds.width + widthChange))
            ceiling.priority = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultLow.rawValue + 1)
            animating = [floor, lead, ceiling]
        } else {
            let held = content.widthAnchor.constraint(equalToConstant: bounds.width)
            held.priority = .defaultLow
            animating = [floor, held]
        }
        NSLayoutConstraint.activate(animating)
        layoutSubtreeIfNeeded()
        whenContentHasDrawn(ready)
    }

    public func animatedResizeDidEnd() {
        guard !animating.isEmpty else { return }
        NSLayoutConstraint.deactivate(animating)
        animating = []
        trailingToEdge?.isActive = true
    }

    /// Calls `body` once the content has drawn at its new width. A web view
    /// draws out of process, frames after its frame changes, and says when
    /// through `_doAfterNextPresentationUpdate:`; started before that, an
    /// animation uncovers the view's backdrop beyond the old drawing. Any
    /// other content draws in step with its frame and is ready at once.
    private func whenContentHasDrawn(_ body: @escaping @MainActor () -> Void) {
        let selector = NSSelectorFromString("_doAfterNextPresentationUpdate:")
        guard content.responds(to: selector) else {
            body()
            return
        }
        let block: @convention(block) () -> Void = { MainActor.assumeIsolated { body() } }
        content.perform(selector, with: block)
    }
}
