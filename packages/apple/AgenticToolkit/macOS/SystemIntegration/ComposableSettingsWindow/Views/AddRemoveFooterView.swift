import AppKit

import AgenticToolkitCoreMacOS
import AgenticToolkitCoreUI

extension ComposableSettings {

    /// The `+`/`−` bar that sits under a list: under a sidebar of records,
    /// under a table of repos. Two clicks, two closures, and a remove button
    /// that is only live when removing would mean something.
    ///
    /// It exists apart from its hosts because a generic view controller cannot
    /// be a button's target — `@objc` members are not allowed in a generic
    /// `NSObject` subclass — and because two hosts wanting the same bar is
    /// exactly the case for one view (`dry`).
    @MainActor
    public final class AddRemoveFooterView: NSView {

        /// Called when `+` is clicked.
        public var onAdd: (() -> Void)?
        /// Called when `−` is clicked. Never called while it is disabled.
        public var onRemove: (() -> Void)?

        /// Reports through `onAdd`.
        public let addButton = NSButton(
            title: "", image: .symbol(named: "plus", accessibilityDescription: "Add"),
            target: nil, action: nil)
        /// Reports through `onRemove`; enabled through `isRemoveEnabled`.
        public let removeButton = NSButton(
            title: "", image: .symbol(named: "minus", accessibilityDescription: "Remove"),
            target: nil, action: nil)

        /// Anything the host wants beside the buttons — a count, an error, a
        /// hint. It sits to their right and takes the slack.
        public var trailingView: NSView? {
            didSet {
                oldValue.map { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
                trailingView.map { stack.addArrangedSubview($0) }
            }
        }

        /// Whether `−` is live. The host decides: only it knows whether the
        /// selected item may be removed.
        public var isRemoveEnabled: Bool {
            get { removeButton.isEnabled }
            set { removeButton.isEnabled = newValue }
        }

        /// Puts a control after `+`/`−` and before `trailingView`: a status
        /// button, a filter. Accessories stay in the order they were added.
        public func addAccessoryView(_ view: NSView) {
            let index = trailingView.flatMap { stack.arrangedSubviews.firstIndex(of: $0) }
                ?? stack.arrangedSubviews.count
            stack.insertArrangedSubview(view, at: index)
        }

        private let stack = NSStackView()
        /// The hairline along the top, when `separatorAbove` asked for one.
        private(set) var separator: NSView?

        /// - Parameters:
        ///   - accessibilityPrefix: `"<prefix>.add"` and `"<prefix>.remove"`
        ///     become the buttons' identifiers, so a UI test can name them.
        ///   - separatorAbove: draws a hairline along the top edge, for a bar
        ///     under a settings sidebar list, which has no edge of its own.
        public init(accessibilityPrefix: String, separatorAbove: Bool = false) {
            super.init(frame: .zero)
            translatesAutoresizingMaskIntoConstraints = false

            addButton.bezelStyle = .smallSquare
            addButton.target = self
            addButton.action = #selector(addPressed)
            addButton.accessibilityID("\(accessibilityPrefix).add")

            removeButton.bezelStyle = .smallSquare
            removeButton.target = self
            removeButton.action = #selector(removePressed)
            removeButton.isEnabled = false
            removeButton.accessibilityID("\(accessibilityPrefix).remove")

            stack.orientation = .horizontal
            stack.alignment = .centerY
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(addButton)
            stack.addArrangedSubview(removeButton)
            addSubview(stack)

            var top = topAnchor
            if separatorAbove {
                let separator = ThemedSeparatorView(role: .border)
                separator.translatesAutoresizingMaskIntoConstraints = false
                addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.topAnchor.constraint(equalTo: topAnchor),
                    separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                    separator.trailingAnchor.constraint(equalTo: trailingAnchor)
                ])
                self.separator = separator
                top = separator.bottomAnchor
            }

            let inset = SettingsLayout.default[.rowSpacing]
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: top, constant: inset),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -inset),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
            ])
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { nil }

        @objc private func addPressed() { onAdd?() }

        @objc private func removePressed() { onRemove?() }
    }
}
