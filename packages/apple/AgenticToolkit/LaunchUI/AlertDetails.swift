import AppKit

/// A collapsed "Details" disclosure for an `NSAlert`, the shape of the system's
/// crash reporter: the alert says what failed in a sentence, and the raw output
/// (a tool's stderr, a stack of `chown` refusals) waits behind a triangle in a
/// scrolling, selectable, monospaced text view, never in the informative text.
///
/// It is the alert's accessory view, so the alert owns it. Run the alert with
/// `NSAlert.runModal()` (two buttons or fewer, so `RowAlert` keeps it native):
/// `RowAlertPanel` does not show accessory views.
@MainActor
public final class AlertDetails: NSStackView {
    public let disclosure = NSButton(title: "", target: nil, action: nil)
    public let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: AlertDetails.width,
                                                                height: AlertDetails.height))
    public let textView = NSTextView()
    private weak var alert: NSAlert?

    public var isExpanded: Bool { !scrollView.isHidden }

    private static let width: CGFloat = 420
    private static let height: CGFloat = 180

    /// Sets a collapsed disclosure holding `details` as `alert`'s accessory view.
    @discardableResult
    public static func attach(_ details: String, to alert: NSAlert) -> AlertDetails {
        let view = AlertDetails(details, alert: alert)
        alert.accessoryView = view
        return view
    }

    private init(_ details: String, alert: NSAlert) {
        self.alert = alert
        super.init(frame: .zero)
        disclosure.bezelStyle = .disclosure
        disclosure.setButtonType(.pushOnPushOff)
        disclosure.state = .off
        disclosure.setAccessibilityLabel("Details")
        disclosure.target = self
        disclosure.action = #selector(toggle)

        let label = NSTextField(labelWithString: "Details")
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor

        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        textView.string = details
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.isHidden = true
        textView.frame = NSRect(origin: .zero, size: scrollView.contentSize)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalToConstant: Self.width),
            scrollView.heightAnchor.constraint(equalToConstant: Self.height)
        ])

        let row = NSStackView(views: [disclosure, label])
        row.spacing = 2
        orientation = .vertical
        alignment = .leading
        spacing = 6
        addArrangedSubview(row)
        addArrangedSubview(scrollView)
        fitHeight()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func toggle() {
        scrollView.isHidden = disclosure.state == .off
        fitHeight()
        // NSAlert sizes its window from the accessory's frame at layout time.
        alert?.layout()
    }

    /// NSAlert reads the accessory's frame, not its constraints.
    private func fitHeight() {
        setFrameSize(NSSize(width: Self.width, height: 0))
        layoutSubtreeIfNeeded()
        setFrameSize(NSSize(width: Self.width, height: fittingSize.height))
    }
}
