import Testing
import AppKit
import AgenticDeveloperToolkit
@testable import AgenticDeveloperToolkitUI

/// `ThemedActionButton` paints its own fill, outline and title because a stock
/// `NSButton` paints itself from the system's colours and ignores the theme
/// entirely. What matters is that each of the three styles says something
/// different — the accent for the action a dialog is *for*, an elevated surface
/// for the ones beside it, the danger colour for one that destroys — and that
/// the pressed, disabled and re-titled states stay in step with the palette.
@MainActor
@Suite("ThemedActionButton (styles, states, sizing)")
struct ThemedActionButtonTests {

    private var palette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.solarizedDark) }
    /// A theme from a different family, not Solarized's own light twin: the two
    /// Solarized themes share one ansi palette, so their accents are the same
    /// colour and a repaint would be indistinguishable from no repaint at all.
    private var lightPalette: SemanticPalette { SemanticPalette(theme: BuiltInThemes.githubLight) }

    private func fill(of button: ThemedActionButton) -> CGColor? { button.layer?.backgroundColor }

    @Test("the primary style fills with the accent")
    func primaryFillsWithAccent() {
        let button = ThemedActionButton(title: "Save", style: .primary)
        button.applyTheme(palette)
        #expect(fill(of: button) == palette.nsColor(.accent).cgColor)
    }

    @Test("the secondary style fills with the elevated surface")
    func secondaryFillsWithElevatedSurface() {
        let button = ThemedActionButton(title: "Cancel")
        button.applyTheme(palette)
        // Secondary is the default, which is what the bare initializer means.
        #expect(button.style == .secondary)
        #expect(fill(of: button) == palette.nsColor(.elevatedSurface).cgColor)
    }

    @Test("the destructive style fills with the danger colour")
    func destructiveFillsWithDanger() {
        let button = ThemedActionButton(title: "Delete", style: .destructive)
        button.applyTheme(palette)
        #expect(fill(of: button) == palette.nsColor(.danger).cgColor)
    }

    @Test("changing the style repaints without a further applyTheme")
    func settingStyleRepaints() {
        let button = ThemedActionButton(title: "Save")
        button.applyTheme(palette)
        button.style = .destructive
        // The observer holds the palette, so the didSet repaint resolves the
        // same colours a fresh `applyTheme` would.
        #expect(fill(of: button) == button.resolvedThemeScope.palette.nsColor(.danger).cgColor)
    }

    @Test("every style answers a press with the one selection colour")
    func pressingAnyStyleUsesSelection() {
        for style in [ThemedActionButton.Style.primary, .secondary, .destructive] {
            let button = ThemedActionButton(title: "Go", style: style)
            button.applyTheme(palette)
            button.isHighlighted = true
            #expect(fill(of: button) == palette.nsColor(.selection).cgColor)
        }
    }

    @Test("releasing a press returns each style to its own colour")
    func releasingReturnsToTheStyleColour() {
        let button = ThemedActionButton(title: "Delete", style: .destructive)
        button.applyTheme(palette)
        button.isHighlighted = true
        button.isHighlighted = false
        #expect(fill(of: button) == button.resolvedThemeScope.palette.nsColor(.danger).cgColor)
    }

    @Test("a disabled button is faded, because it paints its own title and fill")
    func disabledIsFaded() {
        let button = ThemedActionButton(title: "Save", style: .primary)
        #expect(button.alphaValue == 1)
        button.isEnabled = false
        #expect(button.alphaValue < 1)
        button.isEnabled = true
        #expect(button.alphaValue == 1)
    }

    @Test("a stock push button painted by hand fades to the same alpha as a themed one")
    func stockButtonFadesInStep() {
        let stock = FadingPushButton(title: "Sign In", target: nil, action: nil)
        stock.keyEquivalent = "\r"
        stock.applyPrimaryActionTheme(palette)
        let themed = ThemedActionButton(title: "Save", style: .primary)
        stock.isEnabled = false
        themed.isEnabled = false
        #expect(stock.alphaValue == FadingPushButton.disabledAlpha)
        #expect(themed.alphaValue == stock.alphaValue)
        stock.isEnabled = true
        #expect(stock.alphaValue == 1)
    }

    @Test("re-titling repaints, so the new word is on screen in the theme's font")
    func retitlingRepaints() {
        let button = ThemedActionButton(title: "Save", style: .primary)
        button.applyTheme(palette)
        button.title = "Saving…"
        #expect(button.attributedTitle.string == "Saving…")
        let font = button.attributedTitle.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        #expect(font?.pointSize == button.resolvedThemeScope.palette.font(.button).pointSize)
    }

    @Test("a short title still gets the stock button metrics")
    func shortTitleKeepsMinimumSize() {
        let button = ThemedActionButton(title: "OK")
        button.applyTheme(palette)
        #expect(button.intrinsicContentSize.width >= ThemedActionButton.minimumSize.width)
        #expect(button.intrinsicContentSize.height >= ThemedActionButton.minimumSize.height)
    }

    @Test("a long title grows past the minimum rather than being clipped")
    func longTitleGrows() {
        let button = ThemedActionButton(title: "Revoke every credential")
        button.applyTheme(palette)
        #expect(button.intrinsicContentSize.width > ThemedActionButton.minimumSize.width)
    }

    @Test("ThemedSecondaryButton is the secondary style under the name callers use")
    func secondaryTypealias() {
        let button = ThemedSecondaryButton(title: "Cancel")
        #expect(button.style == .secondary)
    }

    @Test("a theme change repaints the fill rather than keeping the old CGColor")
    func themeChangeRepaints() {
        let button = ThemedActionButton(title: "Save", style: .primary)
        button.applyTheme(palette)
        let dark = fill(of: button)
        button.applyTheme(lightPalette)
        #expect(fill(of: button) == lightPalette.nsColor(.accent).cgColor)
        #expect(fill(of: button) != dark)
    }
}
