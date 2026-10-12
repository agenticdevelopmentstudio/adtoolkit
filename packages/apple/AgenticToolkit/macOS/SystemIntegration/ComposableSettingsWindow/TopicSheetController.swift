import AgenticDeveloperToolkitUI
import AppKit

extension ComposableSettings {

    /// A modal sheet: a topic list beside a detail pane (a `SplitViewController`
    /// hosting `panels`), with a problem line and Cancel / OK under it.
    ///
    /// OK asks `validate`; a sentence stays on the sheet as the problem line and
    /// the sheet stays open. With no problem, OK either finishes (`onOK` unset)
    /// or hands over to `onOK` (an owner that saves asynchronously, which then
    /// calls `finish(true)` itself, or `showProblem` and re-enables OK).
    @MainActor
    public final class TopicSheetController: NSViewController {

        public let split: SplitViewController

        /// Asked on OK: a sentence keeps the sheet open and shows it; nil goes on.
        public var validate: () -> String?

        /// Called once when the sheet finishes: true after OK, false after Cancel.
        public var onFinish: (Bool) -> Void

        /// When set, a validated OK calls this instead of finishing; the owner
        /// ends the sheet later with `finish(true)`.
        public var onOK: (() -> Void)?

        /// The line currently shown under the panels.
        public private(set) var problem: String?

        /// Whether the OK button can be pressed.
        public var okEnabled: Bool = true {
            didSet { okButton.isEnabled = okEnabled }
        }

        private let okTitle: String
        private let problemLabel = ThemedLabel(role: .secondaryText, textRole: .caption)
        private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
        private let okButton: NSButton
        private var isFinished = false
        private weak var presentingWindow: NSWindow?

        public init(title: String, panels: [any ComposableSettingsPanel], okTitle: String = "OK",
                    validate: @escaping () -> String?, onFinish: @escaping (Bool) -> Void) {
            self.split = SplitViewController()
            self.validate = validate
            self.onFinish = onFinish
            self.okTitle = okTitle
            self.okButton = NSButton(title: okTitle, target: nil, action: nil)
            super.init(nibName: nil, bundle: nil)
            self.title = title
            split.sortsPanelsByTitle = false
            split.showsSidebarSearch = false
            split.setPanels(panels)
            preferredContentSize = NSSize(width: 760, height: 520)
        }

        @available(*, unavailable)
        public required init?(coder: NSCoder) { fatalError() }

        public override func loadView() {
            // A sheet floats above its window, so it gets the `surface` plane.
            let root = ThemedBackgroundView(role: .surface)
            root.translatesAutoresizingMaskIntoConstraints = false

            addChild(split)
            split.view.translatesAutoresizingMaskIntoConstraints = false

            problemLabel.lineBreakMode = .byTruncatingTail
            problemLabel.maximumNumberOfLines = 2
            problemLabel.stringValue = problem ?? ""
            problemLabel.isHidden = problem == nil
            problemLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            cancelButton.target = self
            cancelButton.action = #selector(cancelTapped)
            cancelButton.keyEquivalent = "\u{1b}"
            cancelButton.observeTheme { button, palette in button.applySecondaryActionTheme(palette) }

            okButton.target = self
            okButton.action = #selector(okTapped)
            okButton.keyEquivalent = "\r"
            okButton.isEnabled = okEnabled
            okButton.observeTheme { button, palette in button.applyPrimaryActionTheme(palette) }

            let buttons = NSStackView(views: [NSView(), cancelButton, okButton])
            buttons.orientation = .horizontal
            buttons.spacing = 12

            let bottom = NSStackView(views: [problemLabel, buttons])
            bottom.orientation = .vertical
            bottom.alignment = .leading
            bottom.spacing = 8
            bottom.edgeInsets = NSEdgeInsets(top: 12, left: 20, bottom: 16, right: 20)
            bottom.translatesAutoresizingMaskIntoConstraints = false
            buttons.translatesAutoresizingMaskIntoConstraints = false

            root.addSubview(split.view)
            root.addSubview(bottom)
            NSLayoutConstraint.activate([
                split.view.topAnchor.constraint(equalTo: root.topAnchor),
                split.view.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                split.view.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                split.view.bottomAnchor.constraint(equalTo: bottom.topAnchor),
                bottom.leadingAnchor.constraint(equalTo: root.leadingAnchor),
                bottom.trailingAnchor.constraint(equalTo: root.trailingAnchor),
                bottom.bottomAnchor.constraint(equalTo: root.bottomAnchor),
                buttons.widthAnchor.constraint(equalTo: bottom.widthAnchor, constant: -40),
                root.widthAnchor.constraint(greaterThanOrEqualToConstant: 620),
                root.heightAnchor.constraint(greaterThanOrEqualToConstant: 420)
            ])
            let preferredWidth = root.widthAnchor.constraint(equalToConstant: 760)
            let preferredHeight = root.heightAnchor.constraint(equalToConstant: 520)
            preferredWidth.priority = .defaultHigh
            preferredHeight.priority = .defaultHigh
            NSLayoutConstraint.activate([preferredWidth, preferredHeight])
            view = root
        }

        /// Shows `sentence` under the panels; nil clears the line.
        public func showProblem(_ sentence: String?) {
            problem = sentence
            guard isViewLoaded else { return }
            problemLabel.stringValue = sentence ?? ""
            problemLabel.isHidden = sentence == nil
        }

        /// The OK button's action.
        public func ok() {
            guard !isFinished else { return }
            showProblem(nil)
            if let sentence = validate() {
                showProblem(sentence)
                return
            }
            if let onOK {
                onOK()
            } else {
                finish(true)
            }
        }

        /// Cancel (also Escape).
        public func cancel() {
            finish(false)
        }

        /// Ends the sheet and calls `onFinish` once; later calls do nothing.
        public func finish(_ accepted: Bool) {
            guard !isFinished else { return }
            isFinished = true
            if let window = presentingWindow, let sheet = view.window {
                window.endSheet(sheet)
            }
            presentingWindow = nil
            onFinish(accepted)
        }

        /// Presents the sheet on `window`, with the panels' first topic selected.
        public func present(on window: NSWindow) {
            let sheetWindow = NSWindow(contentViewController: self)
            sheetWindow.styleMask = [.titled, .resizable]
            sheetWindow.title = title ?? ""
            sheetWindow.contentMinSize = NSSize(width: 620, height: 420)
            presentingWindow = window
            window.beginSheet(sheetWindow)
        }

        @objc private func okTapped() { ok() }
        @objc private func cancelTapped() { cancel() }
    }
}
