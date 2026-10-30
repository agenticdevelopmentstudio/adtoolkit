import AppKit
import AgenticDeveloperToolkit

/// A row of icons that picks one of several panels, drawn as Xcode's navigator
/// selector is: AppKit's own segmented control (`native-controls`) — a capsule
/// track with the chosen icon on a rounded accent selection — themed from the
/// palette and sized to its icons rather than to the space it sits in.
///
/// The bar shows a choice and reports a click; what is chosen lives with the
/// caller, which sets `selectedID` back. A click does not move the keyboard —
/// the control does not take it — so a caller whose panel has a list to type
/// into moves the keyboard there itself.
@MainActor
public final class IconTabBar: NSView, Themeable {

    public struct Item: Sendable, Equatable {
        public let id: String
        public let symbol: String
        public let title: String

        public init(id: String, symbol: String, title: String) {
            self.id = id
            self.symbol = symbol
            self.title = title
        }
    }

    /// Called with the clicked item's `id`.
    public var onSelect: ((String) -> Void)?

    /// The item drawn as chosen; `nil` for none.
    public var selectedID: String? {
        didSet {
            guard selectedID != oldValue else { return }
            showSelection()
        }
    }

    private let items: [Item]
    private let control: NSSegmentedControl
    private var observer: ThemePaletteObserver?

    /// - Parameter accessibilityID: the control's identifier; its segments are
    ///   radio buttons described by their items' titles.
    public init(items: [Item], accessibilityID: String) {
        self.items = items
        control = NSSegmentedControl(
            images: items.map { NSImage(systemSymbolName: $0.symbol, accessibilityDescription: $0.title) ?? NSImage() },
            trackingMode: .selectOne,
            target: nil,
            action: nil)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        control.target = self
        control.action = #selector(changed(_:))
        control.segmentDistribution = .fillEqually
        control.focusRingType = .none
        control.refusesFirstResponder = true
        control.translatesAutoresizingMaskIntoConstraints = false
        for (index, item) in items.enumerated() {
            control.setToolTip(item.title, forSegment: index)
            control.setWidth(32, forSegment: index)
        }
        control.accessibilityID(accessibilityID)
        addSubview(control)

        // The view is exactly the control, so a caller that centres it gets a
        // bar that hugs its icons.
        NSLayoutConstraint.activate([
            control.topAnchor.constraint(equalTo: topAnchor),
            control.bottomAnchor.constraint(equalTo: bottomAnchor),
            control.leadingAnchor.constraint(equalTo: leadingAnchor),
            control.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        control.setContentHuggingPriority(.required, for: .horizontal)

        observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func applyTheme(_ palette: SemanticPalette) {
        // The track takes its shade from the appearance, so a dark theme gets
        // the dark track whatever the system is set to; the selection is the
        // theme's accent.
        let background = palette.nsColor(.windowBackground).usingColorSpace(.sRGB)
        let isDark = (background?.brightnessComponent ?? 1) < 0.5
        control.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        control.selectedSegmentBezelColor = palette.nsColor(.accent)
    }

    private func showSelection() {
        if let selectedID, let index = items.firstIndex(where: { $0.id == selectedID }) {
            control.selectedSegment = index
        } else {
            control.selectedSegment = -1
        }
    }

    @objc private func changed(_ sender: NSSegmentedControl) {
        let index = sender.selectedSegment
        guard items.indices.contains(index) else { return }
        // The caller owns the choice; put back what it last said until it
        // answers, so a refused pick does not stay drawn.
        showSelection()
        onSelect?(items[index].id)
    }
}
