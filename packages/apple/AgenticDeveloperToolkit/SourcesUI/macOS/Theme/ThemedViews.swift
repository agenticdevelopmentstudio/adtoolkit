import AppKit
import AgenticDeveloperToolkit

/// A layer-backed view filled with a single semantic role color. Use it for
/// window/content backgrounds and panels. Repaints live on theme change.
@MainActor
public final class ThemedBackgroundView: NSView, Themeable {
    public let role: ThemeRole

    /// A specific color to paint instead of the role. This is how a themeable
    /// *setting* — a color a theme names outright, rather than a semantic role
    /// it inherits — reaches a view that otherwise just follows the palette.
    /// `nil` puts it back on the role.
    public var colorOverride: NSColor? {
        didSet { applyTheme(resolvedThemeScope.palette) }
    }
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .windowBackground) {
        self.role = role
        super.init(frame: .zero)
        self.wantsLayer = true
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = (colorOverride ?? palette.nsColor(role)).cgColor
    }
}

/// A non-editable label whose text color tracks a `ThemeRole` and whose font
/// tracks a `TextRole` (so both color *and* size/weight follow the theme).
@MainActor
public final class ThemedLabel: NSTextField, Themeable {
    public var role: ThemeRole { didSet { applyTheme(resolvedThemeScope.palette) } }
    public var textRole: TextRole { didSet { applyTheme(resolvedThemeScope.palette) } }

    /// Emphasis *within* the role — a medium field caption, a bold breadcrumb.
    /// `nil` takes the role's own weight, which is what almost every label
    /// wants. It exists because the alternative at those call sites was
    /// `.boldSystemFont(ofSize:)`, which is a font the theme never gets to
    /// choose and a size its scale never reaches.
    public var weight: FontWeight? { didSet { applyTheme(resolvedThemeScope.palette) } }
    private var observer: ThemePaletteObserver?

    public init(
        string: String = "",
        role: ThemeRole = .primaryText,
        textRole: TextRole = .body,
        weight: FontWeight? = nil
    ) {
        self.role = role
        self.textRole = textRole
        self.weight = weight
        super.init(frame: .zero)
        self.isEditable = false
        self.isBordered = false
        self.isBezeled = false
        self.drawsBackground = false
        // The rest of `NSTextField(labelWithString:)`'s defaults, which
        // `init(frame:)` does not give: a field built by frame wraps, breaks on
        // words, and asks for 150 × 64 points. A label does none of that, and
        // every caller of this class uses it as one — a toolbar caption, a table
        // cell, a form value — so a two-line intrinsic height was a caption
        // fighting a 40-point toolbar for room it never needed.
        self.cell?.wraps = false
        self.cell?.usesSingleLineMode = true
        self.lineBreakMode = .byClipping
        self.stringValue = string
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        textColor = palette.nsColor(role)
        font = weight.map { palette.font(textRole, weight: $0) } ?? palette.font(textRole)
    }

    /// A label that wraps onto as many lines as its text needs, at `width`
    /// points — a paragraph or a headline rather than a caption.
    ///
    /// `lineBreakMode` and `maximumNumberOfLines` are ignored while the cell is
    /// in single-line mode, which is the plain init's default, so all four
    /// settings are needed. `preferredMaxLayoutWidth` is what a `fittingSize`
    /// measures the height at; without it the label measures as one long line.
    public static func wrapping(
        _ string: String,
        width: CGFloat,
        role: ThemeRole = .primaryText,
        textRole: TextRole = .body,
        weight: FontWeight? = nil
    ) -> ThemedLabel {
        let label = ThemedLabel(string: string, role: role, textRole: textRole, weight: weight)
        label.cell?.wraps = true
        label.cell?.usesSingleLineMode = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = width
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }
}

/// A label that emphasises the characters a filter matched.
///
/// The ranges are handed in rather than worked out here: what counts as a match
/// belongs to whoever is doing the filtering, and a label that decided for
/// itself would be a second answer to the same question (`dry`). The attributed
/// string is rebuilt on every palette change, because the emphasis is a colour
/// and a weight and both of those are the theme's to say.
@MainActor
public final class ThemedHighlightLabel: NSTextField, Themeable {
    public var role: ThemeRole { didSet { applyTheme(resolvedThemeScope.palette) } }
    public var textRole: TextRole { didSet { applyTheme(resolvedThemeScope.palette) } }
    public var text: String { didSet { applyTheme(resolvedThemeScope.palette) } }
    public var highlightedRanges: [NSRange] { didSet { applyTheme(resolvedThemeScope.palette) } }
    private var observer: ThemePaletteObserver?

    public init(
        string: String = "",
        highlighting ranges: [NSRange] = [],
        role: ThemeRole = .primaryText,
        textRole: TextRole = .body
    ) {
        self.role = role
        self.textRole = textRole
        self.text = string
        self.highlightedRanges = ranges
        super.init(frame: .zero)
        self.isEditable = false
        self.isBordered = false
        self.isBezeled = false
        self.drawsBackground = false
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        let base = palette.font(textRole)
        let string = NSMutableAttributedString(string: text, attributes: [
            .font: base,
            .foregroundColor: palette.nsColor(role)
        ])
        let bold = NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
        let whole = NSRange(location: 0, length: (text as NSString).length)
        for range in highlightedRanges where NSIntersectionRange(range, whole) == range {
            string.addAttributes([
                .font: bold,
                .foregroundColor: palette.nsColor(.accent)
            ], range: range)
        }
        attributedStringValue = string
    }
}

/// An editable text field themed from the palette: control-background fill,
/// primary text, body font, and a placeholder in the placeholder-text role.
@MainActor
public final class ThemedTextField: NSTextField, Themeable {
    private var observer: ThemePaletteObserver?

    public init(string: String = "") {
        super.init(frame: .zero)
        self.stringValue = string
        self.isEditable = true
        self.isBezeled = true
        self.bezelStyle = .roundedBezel
        self.drawsBackground = true
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.controlBackgroundColor
        textColor = palette.primaryTextColor
        font = palette.font(.body)
        if let placeholder = placeholderString {
            placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: palette.placeholderTextColor,
                .font: palette.font(.body)
            ])
        }
    }
}

/// A search field whose text, placeholder and fill follow the palette.
/// `NSSearchField` draws its own bezel and magnifier, so only the parts the
/// theme actually owns are overridden (`native-controls`).
@MainActor
public final class ThemedSearchField: NSSearchField, Themeable {
    private var observer: ThemePaletteObserver?

    public init(placeholder: String = "") {
        super.init(frame: .zero)
        self.placeholderString = placeholder
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        textColor = palette.primaryTextColor
        font = palette.font(.body)
        if let placeholder = placeholderString {
            placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: palette.placeholderTextColor,
                .font: palette.font(.body)
            ])
        }
    }
}

/// A flat, layer-backed button filled with the accent color and an automatically
/// contrasting title. Avoids fighting AppKit's bezel styles so the theme fully
/// controls its appearance.
@MainActor
public final class ThemedButton: NSButton, Themeable {
    private var observer: ThemePaletteObserver?

    public init(title: String, target: AnyObject? = nil, action: Selector? = nil) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        self.isBordered = false
        self.bezelStyle = .regularSquare
        self.wantsLayer = true
        self.layer?.cornerRadius = 6
        self.focusRingType = .none
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = palette.nsColor(.accent).cgColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: palette.onAccentTextColor,
            .font: palette.font(.button)
        ])
    }
}

@MainActor
public extension NSButton {

    /// Paint a stock checkbox's title in the theme's text color and body font.
    ///
    /// The box itself is drawn by the window's appearance (pinned with
    /// ``SemanticPalette/standardAppearance``), but its title takes the
    /// system label color and font unless it is given an attributed one.
    func applyCheckboxTheme(_ palette: SemanticPalette, textRole: TextRole = .body) {
        attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: palette.primaryTextColor,
            .font: palette.font(textRole)
        ])
    }

    /// Paint a stock push button as the *secondary* action of a themed dialog
    /// (Cancel/Close, sitting beside a blue default button).
    ///
    /// A non-default push button draws *nothing* in these themed windows — no
    /// bezel and no title, though it is enabled, sized, and hit-testable (its
    /// sibling default button, the one with a Return key equivalent, draws
    /// fine). `bezelColor` doesn't rescue it either. So the button leaves the
    /// stock bezel behind and paints itself: an elevated surface one clear step
    /// above the window backdrop, outlined, with primary-emphasis text — the
    /// things that say "enabled".
    ///
    /// Borderless buttons have no bezel padding, so callers give the button its
    /// size (matching the default button beside it) rather than leaning on an
    /// intrinsic size that is now just the title.
    func applySecondaryActionTheme(_ palette: SemanticPalette) {
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.backgroundColor = palette.nsColor(.elevatedSurface).cgColor
        layer?.borderColor = palette.nsColor(.outline).cgColor
        contentTintColor = palette.primaryTextColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: palette.primaryTextColor,
            // The theme's button font, like `ThemedButton` — not the control's own
            // `font`, which is never nil on a stock NSButton and so would pin this
            // to AppKit's system font forever.
            .font: palette.font(.button),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ])
    }
}

/// A push button that fades when it is disabled: the one home of the themed
/// disabled look.
///
/// A stock button greys its own bezel and title when it is off; a button that
/// paints its own fill and carries an explicit `.foregroundColor` on its
/// attributed title does not — a disabled Save looked exactly like an enabled
/// one. Fading the whole control keeps fill, outline and title in step
/// whatever the paint. `ThemedActionButton` is one; a stock button painted
/// with an `apply…ActionTheme(_:)` extension, kept stock for its Return key
/// equivalent, is built as one too.
@MainActor
open class FadingPushButton: NSButton {
    /// The alpha a disabled button fades to.
    public static let disabledAlpha: CGFloat = 0.45

    open override var isEnabled: Bool {
        didSet { alphaValue = isEnabled ? 1 : Self.disabledAlpha }
    }
}

/// A themed action button as a *control* rather than a paint job: it sizes
/// itself from the palette's own button font, and it reacts to being pressed.
///
/// The `apply…ActionTheme(_:)` extensions stay for the stock buttons in dialogs
/// that a caller lays out by hand, and for the ones that must remain
/// `NSButton`s because they carry a key equivalent AppKit only honours on a
/// stock push button. What an extension cannot do is the two things a button in
/// a toolbar needs.
///
/// Its size: a borderless button's intrinsic size is only its title, so callers
/// pinned a hard width instead — and `palette.font(.button)` scales with the
/// theme's `sizeScale`, so at 1.5 the word "Resume" is wider than the 68 points
/// it was given and clips with no ellipsis to say so. Sizing from the title
/// that will actually be drawn cannot go wrong that way.
///
/// Its pressed state: the explicit `.foregroundColor` on the attributed title is
/// precisely what stops AppKit dimming a borderless button's text on mouse-down,
/// so the painted version gave no feedback at all when clicked. The fill answers
/// instead.
@MainActor
public final class ThemedActionButton: FadingPushButton, Themeable {

    /// What the button *means*, which is what decides how it is painted. The
    /// three are the three the palette actually distinguishes: the accent for
    /// the action a dialog is for, an elevated surface for the ones beside it,
    /// and the danger colour for one that destroys something.
    public enum Style: Sendable {
        case primary, secondary, destructive
    }

    public var style: Style {
        didSet { applyTheme(resolvedThemeScope.palette) }
    }

    /// The floor: the stock textured-rounded metrics, so a short title still
    /// looks like a button and a row of them stays even.
    public static let minimumSize = NSSize(width: 68, height: 22)

    /// Room around the title, so a long one is not painted edge to edge.
    private static let padding = NSSize(width: 20, height: 8)

    private var observer: ThemePaletteObserver?

    public init(title: String, style: Style = .secondary, target: AnyObject? = nil, action: Selector? = nil) {
        self.style = style
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// Re-titling repaints. The attributed title is built from `title` when the
    /// theme is applied, so assigning `title` alone would change the property
    /// and leave the old word on screen — the bug every caller had to know
    /// about, now the class's own business.
    public override var title: String {
        didSet { applyTheme(resolvedThemeScope.palette) }
    }

    public override var isHighlighted: Bool {
        didSet { paintFill(resolvedThemeScope.palette) }
    }

    public override var intrinsicContentSize: NSSize {
        let title = attributedTitle.size()
        return NSSize(
            width: max(Self.minimumSize.width, ceil(title.width) + Self.padding.width),
            height: max(Self.minimumSize.height, ceil(title.height) + Self.padding.height))
    }

    public func applyTheme(_ palette: SemanticPalette) {
        switch style {
        case .primary:     applyPrimaryActionTheme(palette)
        case .secondary:   applySecondaryActionTheme(palette)
        case .destructive: applyDestructiveActionTheme(palette)
        }
        paintFill(palette)
        invalidateIntrinsicContentSize()
    }

    /// The fill, pressed or at rest. Every style answers a click with the one
    /// `selection` colour, so a row of mixed-style buttons responds
    /// consistently; at rest each returns to the colour its style means.
    ///
    /// It is a separate method from ``applyTheme(_:)`` because `isHighlighted`
    /// changes many times a second while the mouse is down, and re-deriving
    /// fonts and attributed titles on each is work the fill does not need.
    private func paintFill(_ palette: SemanticPalette) {
        let role: ThemeRole
        if isHighlighted {
            role = .selection
        } else {
            switch style {
            case .primary:     role = .accent
            case .secondary:   role = .elevatedSurface
            case .destructive: role = .danger
            }
        }
        layer?.backgroundColor = palette.nsColor(role).cgColor
    }
}

/// The secondary action, which is what this class was before it learned the
/// other two styles. Kept as the name callers already use — it is the style
/// they get by default, so nothing about them changes.
public typealias ThemedSecondaryButton = ThemedActionButton

/// A panel: a layer-backed surface fill with an optional outline stroke and
/// rounded corners. Replaces raw `NSBox`/`.controlBackgroundColor` boxes so the
/// theme drives panel background **and** border/outline color.
@MainActor
public final class ThemedBox: NSView, Themeable {
    public let fillRole: ThemeRole
    public let strokeRole: ThemeRole?
    private var observer: ThemePaletteObserver?

    public init(fill: ThemeRole = .surface, stroke: ThemeRole? = .outline, cornerRadius: CGFloat = 8) {
        self.fillRole = fill
        self.strokeRole = stroke
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = cornerRadius
        self.layer?.borderWidth = stroke == nil ? 0 : 1
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = palette.nsColor(fillRole).cgColor
        if let strokeRole {
            layer?.borderColor = palette.nsColor(strokeRole).cgColor
        }
    }
}

/// A one-point hairline. Defaults to the `border` role; pass `.divider` for a
/// fainter line.
@MainActor
public final class ThemedSeparatorView: NSView, Themeable {
    public let role: ThemeRole
    private var observer: ThemePaletteObserver?

    /// - Parameter axis: the direction the hairline *runs*. A horizontal rule
    ///   is one pixel tall and unconstrained in width; a vertical one is the
    ///   transpose. The default is what every caller before the pane chrome
    ///   wanted, so none of them changed.
    public init(role: ThemeRole = .border, axis: NSUserInterfaceLayoutOrientation = .horizontal) {
        self.role = role
        super.init(frame: .zero)
        self.wantsLayer = true
        // This class activates a constraint on itself, so it only ever makes
        // sense under auto layout — and a caller who forgets this line gets a
        // hairline pinned at (0, 0, 0, 0) by required autoresizing
        // constraints, silently dragging every view positioned off its edges
        // to zero along with it (`InlineChatView`'s composer, once).
        self.translatesAutoresizingMaskIntoConstraints = false
        switch axis {
        case .vertical:
            self.widthAnchor.constraint(equalToConstant: 1).isActive = true
        default:
            self.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        layer?.backgroundColor = palette.nsColor(role).cgColor
    }
}

/// A split view whose divider comes from the palette.
///
/// `NSSplitView` draws its divider from a system color that no theme reaches,
/// so a themed window ends up with a system-grey seam down the middle. This is
/// the one hook AppKit gives for it. Split view *controllers* get it by
/// subclassing `ThemedSplitViewController` rather than assigning this directly.
@MainActor
open class ThemedSplitView: NSSplitView, Themeable {
    private var observer: ThemePaletteObserver?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // `NSSplitView` is born stacked, but `NSSplitViewController` hands out a
        // side-by-side one — so a controller that swapped in a themed split view
        // and never said otherwise silently turned its sidebar into a header.
        // Match what is being replaced: this subclass exists to recolour a
        // divider, not to reorient a window.
        self.isVertical = true
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// Visible to subclasses that paint more than the divider from the theme.
    public private(set) var currentPalette: SemanticPalette = ThemePaletteObserver.currentPalette

    open override var dividerColor: NSColor { currentPalette.nsColor(.divider) }

    open func applyTheme(_ palette: SemanticPalette) {
        currentPalette = palette
        needsDisplay = true
    }
}

/// An `NSSplitViewController` whose divider follows the theme.
///
/// The swap lives in `loadView()` because AppKit allows `splitView` to be
/// assigned only *before* the view is loaded — doing it in `viewDidLoad` raises
/// `NSInternalInconsistencyException` ("The -splitView can only be assigned
/// before the view is loaded"), which AppKit swallows at the top of the run
/// loop and which therefore aborts whatever was mid-way through building the
/// controller. Subclassing keeps that one-shot constraint in one place.
@MainActor
open class ThemedSplitViewController: NSSplitViewController {

    /// The split view to install. Overridable because the assignment is
    /// one-shot and happens here — a subclass that wants a different
    /// `ThemedSplitView` (a wider divider, a differently painted one) has
    /// nowhere else to say so.
    open func makeSplitView() -> ThemedSplitView { ThemedSplitView() }

    open override func loadView() {
        splitView = makeSplitView()
        super.loadView()
    }

    /// A split view with a custom `dividerColor` gets view-backed dividers, and
    /// AppKit asks a view-backed divider whether to hide itself while measuring
    /// the split view inside `viewDidLoad` — before any subclass has added its
    /// items. `NSSplitViewController`'s own implementation indexes
    /// `splitViewItems` unguarded and throws on the empty array, so the answer
    /// for an item that doesn't exist yet has to come from here.
    ///
    /// The upper bound is `dividerIndex + 1`, not `dividerIndex`, because super
    /// answers for the items on **both** sides of the divider — `i` and
    /// `i + 1`. A split with `n` items has `n - 1` dividers, so the last item
    /// has no divider after it and `i == count - 1` is already out of range;
    /// admitting it let super index one past the end and throw
    /// `NSRangeException` from inside this call. That index is not hypothetical
    /// and is not rare in the one case that matters: removing a pane from a
    /// two-item split drops `splitViewItems` to 1 while `NSSplitView` is still
    /// mid-`_updateStackConstraints` and still asking about divider 0. Closing
    /// a pane killed the app.
    ///
    /// The lower bound is the same removal seen one moment earlier. While the
    /// removed item's view is out of `arrangedSubviews` but its item is not yet
    /// out of `splitViewItems`, AppKit's divider walk runs one short and asks
    /// about divider `-1`. Super indexes with it unsigned — `index
    /// 18446744073709551615 beyond bounds [0 .. 0]` — and closing the notes
    /// pane killed the app again, from the same `_updateStackConstraints`.
    open override func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        guard dividerIndex >= 0, dividerIndex + 1 < splitViewItems.count else { return false }
        return super.splitView(splitView, shouldHideDividerAt: dividerIndex)
    }
}

/// A scroll view whose backdrop tracks the window-background role.
@MainActor
public final class ThemedScrollView: NSScrollView, Themeable {
    private var observer: ThemePaletteObserver?

    /// Hands vertical wheel scrolling to the view around it: for a scroll view
    /// sized to fit its content inside one that scrolls, which would otherwise
    /// swallow the wheel and leave the outer one stuck under the pointer.
    public var passesVerticalScrollToEnclosingView = false

    /// What fills the area its document does not cover. The window's
    /// background by default; a scroll view inside a card takes the card's
    /// fill, so a short table never shows a second shade under its rows.
    public var backgroundRole: ThemeRole = .windowBackground {
        didSet { applyTheme(ThemePaletteObserver.currentPalette) }
    }

    public override func scrollWheel(with event: NSEvent) {
        if passesVerticalScrollToEnclosingView, abs(event.scrollingDeltaY) >= abs(event.scrollingDeltaX),
           let outer = superview?.enclosingScrollView {
            outer.scrollWheel(with: event)
        } else {
            super.scrollWheel(with: event)
        }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.drawsBackground = true
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.nsColor(backgroundRole)
    }
}

/// A table whose backdrop tracks a semantic role. A plain `NSTableView` fills
/// itself with the system `controlBackgroundColor`, painting over whatever
/// themed scroll view hosts it — so a list stays system-grey inside an otherwise
/// themed window. Defaults to `surface` so a list reads as its own plane against
/// `windowBackground`; pass `.windowBackground` to make it disappear into the
/// window instead.
///
/// Alternating row colors are off because they come from a system color pair the
/// palette has no say in; a themed list gets its banding, if any, from row views.
@MainActor
public final class ThemedTableView: NSTableView, Themeable {
    public let role: ThemeRole
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .surface) {
        self.role = role
        super.init(frame: .zero)
        self.usesAlternatingRowBackgroundColors = false
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.nsColor(role)
        gridColor = palette.nsColor(.divider)
    }
}

/// A table header painted from the palette. `NSTableHeaderView` is drawn by
/// the system to its last pixel, so under a themed table it is a band of
/// system grey; this one fills itself with `role` and draws each column's
/// `ThemedTableHeaderCell` (a plain cell gets one) over it.
@MainActor
public final class ThemedTableHeaderView: NSTableHeaderView, Themeable {
    public let role: ThemeRole
    private var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .surface) {
        self.role = role
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 24))
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        self.palette = palette
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        palette.nsColor(role).setFill()
        dirtyRect.fill()
        guard let tableView else { return }
        let sort = tableView.sortDescriptors.first
        for (index, column) in tableView.tableColumns.enumerated() where !column.isHidden {
            let rect = headerRect(ofColumn: index)
            guard rect.intersects(dirtyRect) else { continue }
            let cell: ThemedTableHeaderCell
            if let themed = column.headerCell as? ThemedTableHeaderCell {
                cell = themed
            } else {
                cell = ThemedTableHeaderCell(textCell: column.title)
                column.headerCell = cell
            }
            cell.palette = palette
            cell.draw(withFrame: rect, in: self)
            if let key = sort?.key, key == column.sortDescriptorPrototype?.key, let sort {
                cell.drawSortIndicator(withFrame: rect, in: self, ascending: sort.ascending, priority: 0)
            }
        }
        palette.nsColor(.divider).setFill()
        NSRect(x: bounds.minX, y: isFlipped ? bounds.maxY - 1 : bounds.minY, width: bounds.width, height: 1).fill()
    }
}

/// A column title in the palette's secondary text, with a short divider on
/// its trailing edge, for `ThemedTableHeaderView`.
public final class ThemedTableHeaderCell: NSTableHeaderCell {
    /// Set by the header view before each draw; without one the cell draws as the system does.
    var palette: SemanticPalette?

    public override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        guard let palette else {
            super.draw(withFrame: cellFrame, in: controlView)
            return
        }
        let font = palette.font(.caption, weight: .medium)
        let title = NSAttributedString(string: stringValue, attributes: [
            .font: font,
            .foregroundColor: palette.nsColor(.secondaryText)
        ])
        let height = title.size().height
        let textRect = NSRect(
            x: cellFrame.minX + 5, y: cellFrame.midY - height / 2,
            width: max(0, cellFrame.width - 10), height: height)
        title.draw(with: textRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
        palette.nsColor(.divider).setFill()
        NSRect(x: cellFrame.maxX - 1, y: cellFrame.minY + 5, width: 1, height: cellFrame.height - 10).fill()
    }
}

/// The outline counterpart of `ThemedTableView`, for the same reason it exists:
/// an untinted outline paints the system's table background through whatever
/// the theme put behind it.
@MainActor
public final class ThemedOutlineView: NSOutlineView, Themeable {
    public let role: ThemeRole
    private var observer: ThemePaletteObserver?

    public init(role: ThemeRole = .surface) {
        self.role = role
        super.init(frame: .zero)
        self.usesAlternatingRowBackgroundColors = false
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        backgroundColor = palette.nsColor(role)
        gridColor = palette.nsColor(.divider)
    }
}

/// A table row view whose selection fill uses the `selection` role. Observes the
/// theme so reused row instances repaint live; without this, an AppKit-pooled row
/// keeps the palette captured at creation and draws stale selection after a swap.
@MainActor
open class ThemedTableRowView: NSTableRowView, Themeable {
    public private(set) var palette: SemanticPalette = ThemePaletteObserver.currentPalette
    private var observer: ThemePaletteObserver?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func applyTheme(_ palette: SemanticPalette) {
        self.palette = palette
        needsDisplay = true
    }

    public override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        palette.nsColor(.selection).setFill()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 1), xRadius: 4, yRadius: 4)
        path.fill()
    }
}

@MainActor
public extension NSTextField {

    /// Paint a stock editable field from the palette.
    ///
    /// `ThemedTextField` is the class to reach for when a call site builds its
    /// own field. This exists for the ones that cannot: an `NSSecureTextField`,
    /// a field a form builds by kind, a field that already carries a target,
    /// action and delegate. Same five properties either way, stated once.
    ///
    /// The placeholder is rebuilt on every apply rather than colored once,
    /// because `placeholderAttributedString` freezes whatever palette was in
    /// force when it was set.
    func applyEditableFieldTheme(_ palette: SemanticPalette) {
        drawsBackground = true
        backgroundColor = palette.controlBackgroundColor
        textColor = palette.primaryTextColor
        font = palette.font(.body)
        if let placeholder = placeholderString {
            placeholderAttributedString = NSAttributedString(string: placeholder, attributes: [
                .foregroundColor: palette.placeholderTextColor,
                .font: palette.font(.body)
            ])
        }
    }
}

@MainActor
public extension NSButton {

    /// Paint a stock push button as a themed *primary* action — the default
    /// button of a dialog, the Save of a form.
    ///
    /// The companion to ``applySecondaryActionTheme(_:)``, and it exists for
    /// the same reason: a stock bezel is drawn by the appearance, not the
    /// palette, so a themed window's default button comes out in the system
    /// accent no matter what theme is selected.
    func applyPrimaryActionTheme(_ palette: SemanticPalette) {
        applyFilledActionTheme(fill: palette.accentColor, title: palette.onAccentTextColor, palette: palette)
    }

    /// Paint a stock push button as a themed *destructive* action — a Delete
    /// that should read as dangerous in the theme's own red, not the system's.
    func applyDestructiveActionTheme(_ palette: SemanticPalette) {
        applyFilledActionTheme(fill: palette.dangerColor, title: palette.onAccentTextColor, palette: palette)
    }

    private func applyFilledActionTheme(fill: NSColor, title titleColor: NSColor, palette: SemanticPalette) {
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 0
        layer?.backgroundColor = fill.cgColor
        contentTintColor = titleColor
        attributedTitle = NSAttributedString(string: title, attributes: [
            .foregroundColor: titleColor,
            .font: palette.font(.button),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                return style
            }()
        ])
    }
}
