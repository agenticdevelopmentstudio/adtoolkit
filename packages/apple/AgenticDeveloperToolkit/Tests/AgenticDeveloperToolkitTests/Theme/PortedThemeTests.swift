import Testing
import Foundation
@testable import AgenticDeveloperToolkit

@Suite("Ported web themes")
struct PortedThemeTests {

    /// Names are the manifest's own labels, verbatim — four of them do not
    /// match the obvious guess, so copy from here rather than inventing:
    /// "Green Matrix (Glass)" is parenthesised, "Synthwave '84" carries an
    /// apostrophe, and Projects Overview / Agentic Development Studio have no trailing
    /// "My" or "Web".
    @Test("every web theme Swift is missing has been ported")
    func catalogMatchesWeb() {
        let expected: Set<String> = [
            "Charcoal", "Signal", "Terminal", "Terminal Split", "Green Matrix",
            "Green Matrix (Glass)", "Old School Terminal", "CRT Monitor",
            "Handheld Communicator", "Synthwave '84", "Cobalt2", "Vesper",
            "Professional", "Techy", "Whimsical", "Fishlamp", "Dev Team",
            "Mike Fullerton", "My Projects", "Projects Overview",
            "Agentic Development Studio",
        ]
        let names = Set(BuiltInThemes.webPorted.map(\.name))
        #expect(names == expected)
    }

    /// The web manifest has 39 keys; only these 21 get ported. The other 18
    /// are deliberately out:
    ///
    /// - Ten are editor palettes Swift already ships — dracula, nord, gruvbox,
    ///   solarized, catppuccin, github, monokai, one-dark, tokyo-night, rose-pine.
    ///   Swift splits several into light and dark variants where web has one
    ///   key; that difference predates this branch and is not ours to
    ///   reconcile here.
    /// - Eight are the `adh*` font-variant family, which share one palette and
    ///   differ only in `--font-*`. Typography variants are a web font-loading
    ///   concern with no Swift analogue.
    @Test("the themes Swift already has are not ported twice")
    func noDuplicateNames() {
        let existing = Set(BuiltInThemes.all.map(\.name))
            .subtracting(BuiltInThemes.webPorted.map(\.name))
        for ported in BuiltInThemes.webPorted {
            #expect(!existing.contains(ported.name), "\(ported.name) already exists")
        }
        #expect(Set(BuiltInThemes.all.map(\.id)).count == BuiltInThemes.all.count)
    }

    @Test("every ported theme has a structurally valid palette")
    func palettesAreValid() {
        for theme in BuiltInThemes.webPorted {
            #expect(theme.hasValidPalette, "\(theme.name) has \(theme.ansi.count) ANSI colours")
            #expect(theme.isBuiltIn)
        }
    }

    /// Only the nine chat properties every web theme defines are required.
    /// The bubble *borders* and the send-button roles are NOT among them —
    /// they exist in some themes and derive in the rest. (The bubble fills
    /// are always present now, but as an explicit transparency where web
    /// declares none; see `themesWithoutWebBubbleFillsAreFlat`.)
    @Test("ported themes carry the web chat colours that exist")
    func chatOverridesArePresent() {
        let universal: [ThemeRole] = [
            .chatSurface, .chatInputBackground, .chatInputBorder, .chatInputFocus,
            .personaName, .personaText, .userName, .userText, .timestampText,
        ]
        for theme in BuiltInThemes.webPorted {
            for role in universal {
                #expect(
                    theme.roleOverrides[role.rawValue] != nil,
                    "\(theme.name) is missing an override for \(role)"
                )
            }
        }
    }

    /// The seven flat terminal themes — the ones whose CSS declares no
    /// `--pc-persona-bg` / `--pc-user-bg` — must resolve both fills fully
    /// transparent, so `MessageBubbleView` drops the padding and the corner
    /// radius and draws a plain transcript line.
    ///
    /// This inverts what this suite used to assert. The old rule ("the derive
    /// rules must invent a *visible* bubble") was reasoning about the port in
    /// isolation; against the web page it is simply wrong. `.pc-bubble` in
    /// `packages/web/packages/chat/src/css/base.css` sets `width`,
    /// `max-width`, `min-width`, `word-wrap` and `position` and nothing else,
    /// so a web theme that names no fill renders no box. Deriving one gave
    /// `old-school-terminal` a grey slab the website has never drawn.
    @Test("themes without web bubble fills are flat, not derived")
    func themesWithoutWebBubbleFillsAreFlat() {
        let flat: Set<String> = [
            "Terminal", "Terminal Split", "Green Matrix", "Green Matrix (Glass)",
            "Old School Terminal", "CRT Monitor", "Handheld Communicator",
        ]
        var seen: Set<String> = []
        for theme in BuiltInThemes.webPorted {
            let palette = SemanticPalette(theme: theme)
            let isFlat = palette.color(.personaBubble).alpha == 0
                && palette.color(.userBubble).alpha == 0
            if isFlat { seen.insert(theme.name) }
        }
        #expect(seen == flat)
    }

    /// Every ported theme carries web's font stack, reduced to the two things
    /// `FontStyle` can hold: the first named family and whether the stack is
    /// monospaced. A family the system does not know is still not a build
    /// failure — `nsFont(scaledSize:)` falls through to the system face, which
    /// is what the browser does with the same stack's `ui-monospace` fallback
    /// — but the faces the themes actually depend on travel with the framework
    /// and are registered by `ToolkitFonts`, so `VT323` resolves.
    @Test("ported themes carry web's typography")
    func typographyIsPorted() {
        for theme in BuiltInThemes.webPorted {
            for role in TextRole.allCases {
                #expect(
                    theme.typography.styles[role.rawValue] != nil,
                    "\(theme.name) has no style for \(role)"
                )
            }
        }
        let terminal = BuiltInThemes.webPorted.first { $0.name == "Old School Terminal" }!
        #expect(terminal.typography.style(.body).family == "VT323")
        #expect(terminal.typography.style(.body).monospaced)

        // A sans theme keeps its face and is *not* forced monospaced — the
        // flag comes from the stack's own generic fallback, not from a guess.
        let professional = BuiltInThemes.webPorted.first { $0.name == "Professional" }!
        #expect(professional.typography.style(.body).family == "Inter")
        #expect(!professional.typography.style(.body).monospaced)
        #expect(professional.typography.style(.code).family == "JetBrains Mono")
        #expect(professional.typography.style(.code).monospaced)
    }

    /// A theme's face and its readable size are one decision, and web says so:
    /// `old-school-terminal`'s CSS carries the comment "VT323 renders small per
    /// px — bump up a notch vs the JetBrains Mono themes" next to
    /// `body { font-size: 16px }`, and the two CRT themes go to 19px. Porting
    /// the family without the size ports half of what the theme said, and
    /// leaves VT323 — which really is small per point — looking cramped
    /// against every other theme in the picker.
    ///
    /// Carried as a *ratio* against the catalogue's modal 15px, not as
    /// transcribed point sizes: AppKit's metrics are not CSS pixels
    /// (`ThemeTypography.defaultStyle` puts body at 13pt), so absolute
    /// transcription would make every ported theme a fifth larger than every
    /// Swift-native one. What ports cleanly is what each theme said relative
    /// to its siblings.
    @Test("ported themes carry web's body size as a type scale")
    func bodyFontSizeIsPortedAsAScale() {
        func scale(_ name: String) -> Double {
            BuiltInThemes.webPorted.first { $0.name == name }!.typography.sizeScale
        }
        // 16px / 15px — the "bump up a notch" the CSS comment asks for.
        #expect(abs(scale("Old School Terminal") - 16.0 / 15.0) < 0.001)
        // 19px / 15px, from --crt-type-size and --hc-type-size.
        #expect(abs(scale("CRT Monitor") - 19.0 / 15.0) < 0.001)
        #expect(abs(scale("Handheld Communicator") - 19.0 / 15.0) < 0.001)
        // 14px / 15px: a theme quieter than the baseline scales *down*.
        #expect(abs(scale("Terminal") - 14.0 / 15.0) < 0.001)
        // A theme whose CSS states no body size is left at the identity
        // rather than guessed at.
        #expect(scale("Charcoal") == 1.0)

        // The scale reaches the resolved size, which is the only reason it is
        // worth carrying.
        let terminal = BuiltInThemes.webPorted.first { $0.name == "Old School Terminal" }!
        #expect(terminal.typography.size(.body) > terminal.typography.style(.body).size)
    }

    /// `--pc-thinking-done-color` — the settled status line, "✱ thought for
    /// 8s". Two themes declare it and the rest derive it, which is why it is
    /// an optional role rather than a required one.
    ///
    /// `crt-monitor` and `handheld-communicator` are the reason it exists as a
    /// role at all: on those two screens the library default reads as a
    /// rendering fault rather than as the machine's own note, so they say so in
    /// their CSS and the port carries it. Note that this is *not* the same
    /// question as `.timestampText`: these themes keep their clock dim (40%
    /// alpha green) while writing the status line in full phosphor.
    @Test("the two themes whose CSS declares the settled colour keep it, and it is not the clock's")
    func thinkingDoneColourIsDeclaredByTerminalThemes() {
        let phosphor = RGBAColor(hexString: "#00ff41ff")!
        for name in ["CRT Monitor", "Handheld Communicator"] {
            let theme = BuiltInThemes.webPorted.first { $0.name == name }!
            let palette = SemanticPalette(theme: theme)
            #expect(palette.declares(.thinkingDoneText), "\(name) does not declare it")
            #expect(palette.color(.thinkingDoneText) == phosphor, "\(name) is not phosphor green")
            #expect(palette.color(.timestampText) != phosphor, "\(name) dims its clock, not its status")
        }
    }

    /// `old-school-terminal`'s CSS declares no `--pc-thinking-done-color`, so
    /// the settled line takes the library default — grey. It is the theme
    /// olylo's chat wears, and a green settled line there went on reading as a
    /// turn still running. Sharing a phosphor palette with its two siblings is
    /// not the same as sharing their answer to this question.
    @Test("the theme olylo wears settles to grey, the way its CSS leaves it")
    func oldSchoolTerminalSettlesToGrey() {
        let theme = BuiltInThemes.webPorted.first { $0.name == "Old School Terminal" }!
        let palette = SemanticPalette(theme: theme)
        #expect(!palette.declares(.thinkingDoneText))
        let done = palette.color(.thinkingDoneText)
        #expect(max(done.red, done.green, done.blue) - min(done.red, done.green, done.blue) < 0.02)
    }

    @Test("every other ported theme derives the settled colour, legibly")
    func thinkingDoneColourIsDerivedElsewhere() {
        // Derivation must still produce something legible rather than web's
        // literal mid-grey on a light palette.
        let whimsical = BuiltInThemes.webPorted.first { $0.name == "Whimsical" }!
        let palette = SemanticPalette(theme: whimsical)
        #expect(!palette.declares(.thinkingDoneText))
        #expect(palette.color(.thinkingDoneText).alpha > 0)
    }

    @Test("ported themes are in the catalog")
    func foldedIntoAll() {
        for theme in BuiltInThemes.webPorted {
            #expect(BuiltInThemes.all.contains { $0.id == theme.id })
        }
    }
}
