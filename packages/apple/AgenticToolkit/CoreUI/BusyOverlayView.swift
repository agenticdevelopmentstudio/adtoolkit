import AppKit

/// A layer laid over a whole view while something it shows is being changed: a
/// blurred ground, a spinner, an optional line saying what is happening, and no
/// way through to the controls beneath.
///
/// The counterpart of ``DismissibleOverlayView`` with the opposite manners. That
/// one goes away on any press or on Escape; this one goes away only when its
/// owner says the work is done, because what it covers is about to be redrawn
/// and a click landing on the old layout would act on a row that is moving.
///
/// It blends in and out over ``DismissibleOverlayView/fadeDuration`` so the two
/// read as the same kind of surface.
@MainActor
public final class BusyOverlayView: NSView {

    private let backdrop = NSVisualEffectView()
    private let spinner = NSProgressIndicator()
    private let label = NSTextField(labelWithString: "")

    /// - Parameter material: what the blurred ground is made of.
    public init(material: NSVisualEffectView.Material = .hudWindow) {
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        backdrop.material = material
        backdrop.blendingMode = .withinWindow
        backdrop.state = .active
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backdrop)

        spinner.style = .spinning
        spinner.controlSize = .large
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true

        let stack = NSStackView(views: [spinner, label])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
        setAccessibilityRole(.progressIndicator)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// True while laid over a host and not on its way out.
    public var isShowing: Bool { superview != nil && !isHiding }
    private var isHiding = false

    /// Covers `host` entirely and blends in, or — already over `host` — just
    /// updates the message. Calling it again mid-fade-out takes the fade back.
    public func show(in host: NSView, message: String? = nil) {
        label.stringValue = message ?? ""
        label.isHidden = (message ?? "").isEmpty
        setAccessibilityLabel(message)
        isHiding = false
        if superview !== host {
            removeFromSuperview()
            // Above every sibling: the whole point is that nothing beneath is
            // reachable, the titlebar's own accessories included.
            host.addSubview(self, positioned: .above, relativeTo: nil)
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: host.topAnchor),
                leadingAnchor.constraint(equalTo: host.leadingAnchor),
                trailingAnchor.constraint(equalTo: host.trailingAnchor),
                bottomAnchor.constraint(equalTo: host.bottomAnchor)
            ])
            alphaValue = 0
            host.layoutSubtreeIfNeeded()
        }
        spinner.startAnimation(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DismissibleOverlayView.fadeDuration
            animator().alphaValue = 1
        }
    }

    /// Blends out and removes itself. Safe to call when not showing.
    public func hide() {
        guard superview != nil, !isHiding else { return }
        isHiding = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DismissibleOverlayView.fadeDuration
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                // A `show` during the fade took it back; leave it up.
                guard let self, self.isHiding else { return }
                self.isHiding = false
                self.spinner.stopAnimation(nil)
                self.removeFromSuperview()
            }
        }
    }

    // MARK: - Swallowing input

    /// Every press inside lands here, not on the control drawn beneath.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, alphaValue > 0, frame.contains(point) else { return nil }
        return self
    }

    public override func mouseDown(with event: NSEvent) {}
    public override func rightMouseDown(with event: NSEvent) {}
    public override func otherMouseDown(with event: NSEvent) {}
    public override func scrollWheel(with event: NSEvent) {}
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
