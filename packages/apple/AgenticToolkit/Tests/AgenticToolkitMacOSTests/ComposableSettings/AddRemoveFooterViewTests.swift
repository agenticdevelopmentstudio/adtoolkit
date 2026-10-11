import AppKit
import Testing
@testable import AgenticToolkitMacOS

/// The one `+`/`−` bar every settings list uses: its hairline, its buttons,
/// and where their clicks go.
@Suite("AddRemoveFooterView")
@MainActor
struct AddRemoveFooterViewTests {
    private func laidOut(_ footer: ComposableSettings.AddRemoveFooterView) -> ComposableSettings.AddRemoveFooterView {
        footer.widthAnchor.constraint(equalToConstant: 200).isActive = true
        footer.layoutSubtreeIfNeeded()
        return footer
    }

    @Test("a plain footer draws no hairline")
    func noSeparatorByDefault() {
        let footer = ComposableSettings.AddRemoveFooterView(accessibilityPrefix: "t")
        #expect(footer.separator == nil)
    }

    @Test("separatorAbove draws a hairline across the whole top edge, above the buttons")
    func separatorAcrossTop() throws {
        let footer = laidOut(ComposableSettings.AddRemoveFooterView(accessibilityPrefix: "t", separatorAbove: true))
        let separator = try #require(footer.separator)
        #expect(separator.superview === footer)
        #expect(separator.frame.width == footer.bounds.width)
        let buttonFrame = footer.convert(footer.addButton.bounds, from: footer.addButton)
        let separatorFrame = footer.convert(separator.bounds, from: separator)
        // Flipped or not, the hairline sits on the opposite side of the buttons from the bottom edge.
        let buttonsBelowSeparator = footer.isFlipped
            ? buttonFrame.minY >= separatorFrame.maxY
            : buttonFrame.maxY <= separatorFrame.minY
        #expect(buttonsBelowSeparator)
    }

    @Test("the buttons are named from the prefix and report through their closures")
    func buttonsRoute() {
        let footer = ComposableSettings.AddRemoveFooterView(accessibilityPrefix: "t", separatorAbove: true)
        var added = 0
        var removed = 0
        footer.onAdd = { added += 1 }
        footer.onRemove = { removed += 1 }
        footer.isRemoveEnabled = true
        footer.addButton.performClick(nil)
        footer.removeButton.performClick(nil)
        #expect(added == 1)
        #expect(removed == 1)
        #expect(footer.addButton.accessibilityIdentifier() == "t.add")
        #expect(footer.removeButton.accessibilityIdentifier() == "t.remove")
    }
}
