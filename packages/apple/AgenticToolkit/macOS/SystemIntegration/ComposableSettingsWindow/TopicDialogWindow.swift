import AppKit

extension ComposableSettings {

    /// A modal dialog built as a settings window: the same topic sidebar,
    /// toolbar and help drawer, resizable, with a problem line and Cancel / OK
    /// under the detail pane. The close button is Cancel, Escape is Cancel and
    /// Return is OK.
    ///
    /// OK asks `validate`; a sentence stays in the dialog as the problem line and
    /// the dialog stays open. With no problem, OK either finishes (`onOK` unset)
    /// or hands over to `onOK` (an owner that saves asynchronously, which then
    /// calls `finish(true)` itself, or `showProblem` and re-enables OK).
    @MainActor
    public final class TopicDialogWindow: SettingsWindow {

        public var split: SplitViewController {
            guard let split = viewController else { preconditionFailure("a settings window always has its split") }
            return split
        }

        /// Asked on OK: a sentence keeps the dialog open and shows it; nil goes on.
        public var validate: () -> String?

        /// Called once when the dialog finishes: true after OK, false after Cancel.
        public var onFinish: (Bool) -> Void

        /// When set, a validated OK calls this instead of finishing; the owner
        /// ends the dialog later with `finish(true)`.
        public var onOK: (() -> Void)?

        /// The line currently shown beside the buttons.
        public private(set) var problem: String?

        /// Whether the OK button can be pressed.
        public var okEnabled: Bool = true {
            didSet { okButton.isEnabled = okEnabled }
        }

        public private(set) var isFinished = false

        let problemLabel = NSTextField(wrappingLabelWithString: "")
        let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
        let okButton: NSButton
        private let dialogTitle: String
        /// Set while `NSApp.runModal(for:)` is running this dialog.
        private var isRunningModal = false

        /// `windowID` keys the dialog's saved size and position.
        public init(windowID: String, title: String, panels: [any ComposableSettingsPanel],
                    okTitle: String = "OK",
                    validate: @escaping () -> String?, onFinish: @escaping (Bool) -> Void) {
            self.validate = validate
            self.onFinish = onFinish
            self.okButton = NSButton(title: okTitle, target: nil, action: nil)
            self.dialogTitle = title
            super.init(windowID: windowID)
            windowTitle = title
            // A dialog is not minimised: it holds up the app until it is answered.
            windowStyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
            // Opens centred at this size the first time, then where it was left;
            // an owner with more to show sets its own spec.
            windowSpec = WindowSpec(defaultSize: NSSize(width: 860, height: 600),
                                    minSize: NSSize(width: 680, height: 460),
                                    defaultPosition: .center, persistsFrame: true)
            // Its topics are steps in one task, in the order given, and few
            // enough that a search field would only take room.
            split.sortsPanelsByTitle = false
            split.showsSidebarSearch = false
            split.setPanels(panels)
            split.detailFooterView = makeFooter()
        }

        /// "Title — Panel": which record the dialog is about, and which topic is on screen.
        public override func toolbarTitle(forPanel panelTitle: String?) -> String {
            guard let panelTitle, !panelTitle.isEmpty else { return dialogTitle }
            return "\(dialogTitle) — \(panelTitle)"
        }

        /// Builds the window, its first topic selected, without showing it.
        @discardableResult
        public func prepare() -> NSWindow? {
            if window == nil { loadWindow() }
            if split.selectedPanel == nil, let first = split.panels.first {
                split.selectPanel(first)
            }
            return window
        }

        /// Shows the dialog app-modally. Returns at once; `onFinish` reports the answer.
        ///
        /// The modal session starts on the next pass of the run loop, not inside
        /// this call: a caller running as a main-queue block (a button action
        /// reached from SwiftUI, a `Task` on the main actor) would otherwise hold
        /// the main queue for as long as the dialog is up, and every `await` the
        /// dialog's own work makes on the main actor would wait for it to close.
        public func present() {
            guard let window = prepare() else { return }
            CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue) { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, !self.isFinished else { return }
                    self.isRunningModal = true
                    // A dialog is answered before anything else, so it comes forward.
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.runModal(for: window)
                    self.isRunningModal = false
                }
            }
            CFRunLoopWakeUp(CFRunLoopGetMain())
        }

        /// Shows `sentence` beside the buttons; nil clears it.
        public func showProblem(_ sentence: String?) {
            problem = sentence
            problemLabel.stringValue = sentence ?? ""
            problemLabel.isHidden = sentence == nil
        }

        /// The OK button's action (also Return).
        public func ok() {
            // While a save is in flight OK is disabled, and Return is refused with it.
            guard !isFinished, okEnabled else { return }
            showProblem(nil)
            if let sentence = validate() {
                showProblem(sentence)
                return
            }
            if let onOK {
                // One save in flight: the owner re-enables OK when it shows a problem.
                okEnabled = false
                onOK()
            } else {
                finish(true)
            }
        }

        /// Cancel (also Escape and the close button).
        public func cancel() {
            finish(false)
        }

        /// Ends the dialog and calls `onFinish` once; later calls do nothing.
        public func finish(_ accepted: Bool) {
            guard !isFinished else { return }
            isFinished = true
            if isRunningModal {
                NSApp.stopModal()
                // `stopModal` takes effect when the modal loop next handles an
                // event; an OK finished from an awaited save comes from no event,
                // so one is posted to end the loop now.
                if let wake = NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [],
                                                 timestamp: 0, windowNumber: 0, context: nil,
                                                 subtype: 0, data1: 0, data2: 0) {
                    NSApp.postEvent(wake, atStart: true)
                }
            }
            window?.orderOut(nil)
            let finished = onFinish
            // Release what the owner captured; the dialog is done with it.
            onFinish = { _ in }
            onOK = nil
            validate = { nil }
            finished(accepted)
        }

        /// The close button cancels, and `finish` takes the window down.
        @objc public func windowShouldClose(_ sender: NSWindow) -> Bool {
            cancel()
            return false
        }

        private func makeFooter() -> NSView {
            let footer = NSView()

            problemLabel.textColor = .systemRed
            problemLabel.maximumNumberOfLines = 2
            problemLabel.isHidden = true
            problemLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            problemLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

            // Standard push buttons at the regular size: the shape every Mac dialog has.
            for button in [cancelButton, okButton] {
                button.bezelStyle = .push
                button.controlSize = .regular
                button.target = self
                button.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            cancelButton.action = #selector(cancelClicked)
            cancelButton.keyEquivalent = "\u{1b}"
            okButton.action = #selector(okClicked)
            okButton.keyEquivalent = "\r"
            okButton.isEnabled = okEnabled

            for view in [problemLabel, cancelButton, okButton] {
                view.translatesAutoresizingMaskIntoConstraints = false
                footer.addSubview(view)
            }
            NSLayoutConstraint.activate([
                // OK is never narrower than Cancel.
                okButton.widthAnchor.constraint(greaterThanOrEqualTo: cancelButton.widthAnchor),
                okButton.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -20),
                okButton.bottomAnchor.constraint(equalTo: footer.bottomAnchor, constant: -20),
                okButton.topAnchor.constraint(equalTo: footer.topAnchor, constant: 12),
                cancelButton.trailingAnchor.constraint(equalTo: okButton.leadingAnchor, constant: -12),
                cancelButton.firstBaselineAnchor.constraint(equalTo: okButton.firstBaselineAnchor),
                problemLabel.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 20),
                problemLabel.trailingAnchor.constraint(lessThanOrEqualTo: cancelButton.leadingAnchor, constant: -20),
                problemLabel.centerYAnchor.constraint(equalTo: okButton.centerYAnchor),
                problemLabel.topAnchor.constraint(greaterThanOrEqualTo: footer.topAnchor, constant: 8)
            ])
            return footer
        }

        @objc private func okClicked() { ok() }
        @objc private func cancelClicked() { cancel() }
    }
}
