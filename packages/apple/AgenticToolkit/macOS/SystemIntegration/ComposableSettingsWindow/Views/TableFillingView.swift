import AppKit

extension ComposableSettings {

    /// Holds an ``EditableTableCard`` at the top, full width, and gives its
    /// table whatever height is left, so the table grows and shrinks with the
    /// window and never draws empty rows below a short card. The card itself
    /// keeps a fixed height by design; telling it the height is this view's job.
    @MainActor
    public final class TableFillingView: NSView {

        public let card: EditableTableCard

        /// `minimumHeight` is the least the view asks of its container.
        public init(card: EditableTableCard, minimumHeight: CGFloat = 120) {
            self.card = card
            super.init(frame: .zero)
            card.translatesAutoresizingMaskIntoConstraints = false
            addSubview(card)
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: topAnchor),
                card.leadingAnchor.constraint(equalTo: leadingAnchor),
                card.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
            // Shrinks below the card's current height so the slack can go negative.
            heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight).isActive = true
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { nil }

        public override func layout() {
            super.layout()
            let slack = bounds.height - card.frame.height
            if abs(slack) > 0.5 { card.tableHeight += slack }
        }
    }
}
