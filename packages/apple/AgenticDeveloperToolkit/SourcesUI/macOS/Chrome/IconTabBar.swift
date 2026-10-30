import AppKit
import AgenticDeveloperToolkit

/// A bar of icon buttons that picks one of several panels, drawn as Xcode's
/// navigator bar is: an outlined, rounded frame around the row, with the chosen
/// icon on an accent chip and the others in the secondary text colour.
///
/// The bar shows a choice and reports a click; what is chosen lives with the
/// caller, which sets `selectedID` back. A click does not move the keyboard —
/// buttons do not take it — so a caller whose panel has a list to type into
/// moves the keyboard there itself.
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
            applyTheme(resolvedThemeScope.palette)
        }
    }

    private let items: [Item]
    private var buttons: [String: NSButton] = [:]
    private var observer: ThemePaletteObserver?

    /// - Parameter accessibilityPrefix: each button's identifier is this
    ///   followed by its item's `id`.
    public init(items: [Item], accessibilityPrefix: String) {
        self.items = items
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1

        let cells: [NSView] = items.map { item in
            let button = NSButton(
                image: NSImage(systemSymbolName: item.symbol, accessibilityDescription: item.title) ?? NSImage(),
                target: self,
                action: #selector(clicked(_:)))
            button.isBordered = false
            button.imagePosition = .imageOnly
            button.setButtonType(.momentaryChange)
            button.toolTip = item.title
            button.identifier = NSUserInterfaceItemIdentifier(item.id)
            button.wantsLayer = true
            button.layer?.cornerRadius = 6
            button.translatesAutoresizingMaskIntoConstraints = false
            button.accessibilityID(accessibilityPrefix + item.id)
            buttons[item.id] = button

            // Each item gets an equal share of the bar; the chip is a fixed
            // size centred in it, as Xcode's is, rather than the whole share.
            let cell = NSView()
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 28),
                button.heightAnchor.constraint(equalToConstant: 22)
            ])
            return cell
        }

        let stack = NSStackView(views: cells)
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .centerY
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            heightAnchor.constraint(equalToConstant: 28)
        ])
        for cell in cells {
            cell.heightAnchor.constraint(equalTo: stack.heightAnchor).isActive = true
        }

        observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.borderColor = palette.nsColor(.outline).cgColor
        layer?.backgroundColor = palette.nsColor(.windowBackground).cgColor
        for item in items {
            guard let button = buttons[item.id] else { continue }
            let selected = item.id == selectedID
            button.layer?.backgroundColor = selected ? palette.nsColor(.accent).cgColor : NSColor.clear.cgColor
            button.contentTintColor = palette.nsColor(selected ? .onAccentText : .secondaryText)
            button.setAccessibilityValue(selected ? "selected" : nil)
        }
    }

    @objc private func clicked(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        onSelect?(id)
    }
}
