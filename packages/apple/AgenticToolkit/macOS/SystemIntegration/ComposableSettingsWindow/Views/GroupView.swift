import AppKit
import AgenticToolkitCore
import AgenticToolkitCoreMacOS

extension ComposableSettings {

    /// How a view sits in a group's card.
    public enum CardRowStyle: Sendable {
        /// A setting of its own: padded above and below, and divided from the
        /// row above it by a hairline.
        case row
        /// Prose or a value that belongs to the row above — tucked up against
        /// it, with no divider between them. A run of these reads as one block.
        /// As the *first* thing in a card it becomes a `row`: there is nothing
        /// above it to continue.
        case continuation
    }

    /// A row that decides for itself whether it belongs on screen.
    ///
    /// `GroupView` listens so the card can close up around a row that has
    /// hidden itself — its padding and the hairline above it go with it. An
    /// `NSStackView` collapses a hidden arranged subview, but the row's padding
    /// cell is not hidden just because its content is, so without this a
    /// dismissed hint leaves an empty band and a stray divider behind.
    @MainActor
    public protocol SelfHidingSettingsView: NSView {
        /// Called after the view has changed its own `isHidden`.
        var onVisibilityChange: (() -> Void)? { get set }
    }

    /// A setting row built from a view model, carrying that model's
    /// ``AbstractViewModel/explanation``.
    ///
    /// The explanation is reference prose, and reference prose lives in the
    /// panel's help drawer, never under the control: a blurb under every row is
    /// read once and then costs the panel its height for good. `GroupView`
    /// collects it as a ``HelpNote`` instead of drawing it, and
    /// `SettingsPanelViewController` adds the notes to the drawer — so an
    /// `explanation:` written anywhere reaches the drawer without its panel
    /// having to repeat it.
    @MainActor
    public protocol ExplainedSettingsView: NSView {
        /// The setting's own label, naming it in the help drawer.
        var settingTitle: String? { get }
        /// The prose to put in the help drawer; nil or empty adds nothing.
        var settingExplanation: String? { get }
    }

    /// One setting's explanation, on its way to the help drawer.
    public struct HelpNote: Sendable, Equatable {
        public let setting: String?
        public let text: String

        /// The paragraph the drawer shows: the setting named first, so a note
        /// that says "when on" still says what is on.
        public var paragraph: String {
            guard let setting, !setting.isEmpty else { return text }
            return "\(setting): \(text)"
        }
    }

    /// A group of settings, drawn the way System Settings draws one: a caption
    /// *outside* and above a rounded card, and inside the card one padded row
    /// per setting with a hairline between them.
    ///
    /// The caption sits outside the card because that is what separates a
    /// group's name from its contents at a glance — a title as the card's first
    /// row reads as just another setting.
    @MainActor
    public class GroupView: NSView, SettingsViewProtocol {

        /// The card holding the rows. Exposed so a panel can address the box
        /// itself (measuring it, insetting something over it) without reaching
        /// through `subviews`.
        public let cardView: NSView

        /// Whether the caption carries a disclosure triangle after it that
        /// shows and hides the card. Off by default.
        public var isDisclosable = false {
            didSet {
                disclosureButton.isHidden = !isDisclosable
                // Only a disclosable header gives up its width: the triangle
                // sits right after the title, not at the far edge.
                headerSpacer.isHidden = !isDisclosable
                header.setContentHuggingPriority(
                    isDisclosable ? .defaultHigh : .defaultLow, for: .horizontal)
            }
        }

        /// Whether the card shows. True by default; the triangle flips it.
        public var isDisclosed = true {
            didSet {
                cardView.isHidden = !isDisclosed
                disclosureButton.state = isDisclosed ? .on : .off
                disclosureButton.setAccessibilityLabel(isDisclosed ? "Hide" : "Show")
            }
        }

        /// The triangle after the caption, shown while `isDisclosable`.
        public let disclosureButton = NSButton()

        private let header: NSView
        private let headerRow = NSStackView()
        private let headerSpacer = NSView()
        private let outerStack = NSStackView()
        private let rowStack = NSStackView()
        private var rows: [CardRow] = []

        /// The caption over the card, which titles this group's help topic.
        /// Nil for a group headed by a custom view.
        public private(set) var title: String?

        /// The explanations of the settings in this card, top to bottom, for the
        /// help drawer. See ``ExplainedSettingsView``.
        public private(set) var helpNotes: [HelpNote] = []

        public convenience init(withTitle title: String) {
            self.init(withHeaderView: HeaderView(title: title))
            self.title = title
        }

        /// A group headed by an arbitrary view instead of the standard caption
        /// header — e.g. a picker's detail pane leading with a heading-role label.
        public init(withHeaderView header: NSView) {
            self.cardView = ThemedBox(
                fill: .elevatedSurface,
                stroke: nil,
                cornerRadius: SettingsLayout.default[.cardCornerRadius])
            self.header = header

            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false

            self.outerStack.orientation = .vertical
            self.outerStack.alignment = .leading
            self.outerStack.spacing = SettingsLayout.default[.captionSpacing]
            self.outerStack.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.outerStack)
            Self.pinToEdges(self.outerStack, of: self)

            self.rowStack.orientation = .vertical
            self.rowStack.alignment = .leading
            self.rowStack.spacing = 0
            self.rowStack.translatesAutoresizingMaskIntoConstraints = false

            header.translatesAutoresizingMaskIntoConstraints = false
            self.disclosureButton.bezelStyle = .disclosure
            self.disclosureButton.setButtonType(.pushOnPushOff)
            self.disclosureButton.title = ""
            self.disclosureButton.state = .on
            self.disclosureButton.setAccessibilityLabel("Hide")
            self.disclosureButton.target = self
            self.disclosureButton.action = #selector(disclosurePressed(_:))
            self.disclosureButton.isHidden = true
            self.headerSpacer.setContentHuggingPriority(.init(1), for: .horizontal)
            self.headerSpacer.isHidden = true
            self.headerRow.orientation = .horizontal
            self.headerRow.alignment = .centerY
            self.headerRow.spacing = 4
            self.headerRow.translatesAutoresizingMaskIntoConstraints = false
            [header, self.disclosureButton, self.headerSpacer].forEach(self.headerRow.addArrangedSubview)
            self.outerStack.addArrangedSubview(self.headerRow)
            self.cardView.translatesAutoresizingMaskIntoConstraints = false
            self.outerStack.addArrangedSubview(self.cardView)
            self.cardView.addSubview(self.rowStack)
            Self.pinToEdges(self.rowStack, of: self.cardView)

            // Both bands span the group, so a caption never widens the card and a
            // full-width row (a slider, a grid) actually gets the whole card.
            NSLayoutConstraint.activate([
                self.headerRow.widthAnchor.constraint(equalTo: self.outerStack.widthAnchor),
                self.cardView.widthAnchor.constraint(equalTo: self.outerStack.widthAnchor)
            ])
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func disclosurePressed(_ sender: NSButton) {
            isDisclosed = sender.state == .on
        }

        // Each group fills its parent stack's width so that any child that
        // wants to span the full panel (sliders with trailing captions, dividers,
        // etc.) actually can. Items inside the group still control their own
        // horizontal layout via content-hugging priorities.
        public override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            guard let parent = self.superview else { return }
            self.widthAnchor.constraint(equalTo: parent.widthAnchor).isActive = true
        }

        /// Adds `view` as the card's next row.
        ///
        /// The style is the caller's to state rather than the card's to guess.
        /// It was inferred from the view's *type* once — prose was assumed to
        /// annotate the row above it — which turned a list of plugin load
        /// failures into an unseparated run of jammed-together lines, and sliced
        /// one model description into six divided rows. What a view means in a
        /// card is not knowable from what class it is.
        ///
        /// A view built from a view model with an `explanation`
        /// (``ExplainedSettingsView``) brings it along into ``helpNotes``, for
        /// the help drawer — not into the card.
        public func addSettingSubview(_ view: NSView, style: CardRowStyle = .row) {
            if let note = Self.helpNote(for: view) { helpNotes.append(note) }
            let row = CardRow(content: view, style: style)
            if let selfHiding = view as? any SelfHidingSettingsView {
                selfHiding.onVisibilityChange = { [weak self, weak row] in
                    row?.syncVisibility()
                    self?.updateSeparators()
                }
            }
            append(row)
        }

        private func append(_ row: CardRow) {
            rows.append(row)
            rowStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: rowStack.widthAnchor).isActive = true
            updateSeparators()
        }

        /// `view`'s view-model explanation as a help note, or nil when it has none.
        private static func helpNote(for view: NSView) -> HelpNote? {
            guard let explained = view as? any ExplainedSettingsView,
                  let text = explained.settingExplanation?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty
            else { return nil }
            return HelpNote(setting: explained.settingTitle, text: text)
        }

        /// A divider belongs above a row only when there is a visible row for it
        /// to divide this one from — so a hidden first row never leaves a
        /// hairline stranded at the top of the card.
        private func updateSeparators() {
            var hasVisiblePredecessor = false
            for row in rows {
                row.showsSeparator = hasVisiblePredecessor && row.style == .row
                if !row.isHidden { hasVisiblePredecessor = true }
            }
        }
    }

    /// One row of a group's card: the hairline that divides it from the row
    /// above, the card's padding, and the setting itself.
    ///
    /// The row *is* its content's visibility — hiding the content hides the row,
    /// so the card closes up rather than keeping a padded blank band where a
    /// `ConditionalView` used to be.
    @MainActor
    private final class CardRow: NSView {

        let content: NSView
        let style: ComposableSettings.CardRowStyle

        private let line = ThemedSeparatorView(role: .divider)
        /// The band the hairline occupies. `ThemedSeparatorView` pins its own
        /// height to one point, so the space it takes is this container's to
        /// state — which is also how the divider can be closed to nothing on a
        /// row that has no predecessor to be divided from.
        private let separatorBand = NSView()
        private let separatorHeight: NSLayoutConstraint

        var showsSeparator: Bool = false {
            didSet {
                guard showsSeparator != oldValue else { return }
                line.isHidden = !showsSeparator
                separatorHeight.constant = showsSeparator
                    ? ComposableSettings.SettingsLayout.default[.dividerThickness]
                    : 0
            }
        }

        init(content: NSView, style: ComposableSettings.CardRowStyle) {
            self.content = content
            self.style = style
            self.separatorHeight = separatorBand.heightAnchor.constraint(equalToConstant: 0)

            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false
            content.translatesAutoresizingMaskIntoConstraints = false
            separatorBand.translatesAutoresizingMaskIntoConstraints = false
            line.isHidden = true
            separatorBand.addSubview(line)
            addSubview(separatorBand)
            addSubview(content)

            let horizontal = ComposableSettings.SettingsLayout.default[.cardHorizontalInset]
            let vertical = ComposableSettings.SettingsLayout.default[.cardVerticalInset]
            // A continuation is tucked against what it continues, so it takes no
            // top padding of its own; a row is padded on both sides.
            let topInset = style == .row ? vertical : 0

            NSLayoutConstraint.activate([
                // Inset from the leading edge so the hairline starts under the
                // labels — System Settings' own separator inset.
                line.leadingAnchor.constraint(
                    equalTo: separatorBand.leadingAnchor, constant: horizontal),
                line.trailingAnchor.constraint(equalTo: separatorBand.trailingAnchor),
                line.topAnchor.constraint(equalTo: separatorBand.topAnchor),

                separatorBand.leadingAnchor.constraint(equalTo: leadingAnchor),
                separatorBand.trailingAnchor.constraint(equalTo: trailingAnchor),
                separatorBand.topAnchor.constraint(equalTo: topAnchor),
                separatorHeight,

                content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontal),
                content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontal),
                content.topAnchor.constraint(equalTo: separatorBand.bottomAnchor, constant: topInset),
                content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vertical)
            ])

            syncVisibility()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// Takes the row's visibility from its content's, so a stack that
        /// collapses hidden arranged subviews collapses this one too.
        func syncVisibility() {
            isHidden = content.isHidden
        }
    }
}
