import Foundation

/// App-wide semantic color roles. UI reads colors by *role*, never by raw ANSI
/// slot, so a control's meaning ("primary text", "accent") survives any theme
/// swap. A 16-color terminal scheme maps onto these via `SemanticPalette`.
public enum ThemeRole: String, CaseIterable, Sendable {
    // Backgrounds (lowest → highest elevation)
    /// Base window / app backdrop.
    case windowBackground
    /// Panel / card surface elevated above the window backdrop.
    case surface
    /// Strongly elevated surface (HUD, popover, floating panel).
    case elevatedSurface
    /// Background of editable controls (text fields, wells, list rows).
    case controlBackground
    /// Fill of a card or settings group box. Derives to `elevatedSurface`, the
    /// tone it always had; its own role so a theme can set cards apart from
    /// the pane title bars and footers, which stay on `elevatedSurface`.
    case card

    // Text (highest → lowest emphasis)
    /// Primary, high-emphasis text.
    case primaryText
    /// Secondary, medium-emphasis text (subtitles, captions).
    case secondaryText
    /// Tertiary, low-emphasis text ("no data", disabled).
    case tertiaryText
    /// Placeholder / hint text in empty fields.
    case placeholderText
    /// Text/icons drawn on top of an `accent` fill (auto-contrasted).
    case onAccentText

    // Status / accents
    /// Primary accent (links, selected controls, key data series).
    case accent
    /// Success / active / positive state.
    case success
    /// Warning / caution state.
    case warning
    /// Error / destructive / negative state.
    case danger
    /// Informational / neutral-highlight state.
    case info

    // Lines
    /// Hairline borders / separators.
    case border
    /// Stronger stroke for box outlines and focus rings.
    case outline
    /// Subtle divider, fainter than `border`.
    case divider

    // Selection / caret
    /// Selection / highlight fill.
    case selection
    /// Text drawn on top of a `selection` fill (auto-contrasted).
    case selectionText
    /// The line that marks a selection: a bar down the leading edge of a
    /// selected row, the outline of the front tab card. Clear by default, so a
    /// theme opts in by declaring it and every other theme draws no line.
    case selectionEdge
    /// Text-insertion cursor.
    case cursor

    // Chat — mirrors the web theme's `--pc-*` namespace so a theme reads the
    // same on both platforms. Every one derives from a role above by default,
    // so all built-in themes get a correct chat appearance without authoring
    // sixteen colours per theme; a theme overrides only what should differ.

    /// Fill behind a message from the persona/assistant.
    case personaBubble
    /// Hairline around a persona bubble.
    case personaBubbleBorder
    /// Text inside a persona bubble.
    case personaText
    /// The persona's display name above its bubble.
    case personaName
    /// Fill behind a message from the local user.
    case userBubble
    /// Hairline around a user bubble.
    case userBubbleBorder
    /// Text inside a user bubble.
    case userText
    /// The user's display name above their bubble.
    case userName
    /// Backdrop of the transcript region, behind the bubbles.
    case chatSurface
    /// Fill of the composer's text field.
    case chatInputBackground
    /// Composer border at rest.
    case chatInputBorder
    /// Composer border while focused.
    case chatInputFocus
    /// Send button fill at rest.
    case sendButton
    /// Glyph/text on the send button.
    case sendButtonText
    /// Send button fill on hover.
    case sendButtonHover
    /// Inline message timestamps.
    case timestampText
    /// The status line once a turn has settled ("✱ thought for 8s") — web's
    /// `--pc-thinking-done-color`, whose CSS default is a flat `#8a8a8a`.
    ///
    /// Its own role rather than a reuse of `timestampText` because the two
    /// disagree on the themes that care: `crt-monitor` and
    /// `handheld-communicator` set this to their phosphor green while leaving
    /// `--pc-time-color` a dim 40%-alpha green, and a monochrome terminal
    /// palette has no grey in it at all.
    case thinkingDoneText
    /// The status line while nothing is happening — ADT's own idle muttering
    /// ("\u{2299} waiting to zeeble\u{2026}"), which web has no token for because web
    /// renders no `.pc-typing` at all when there is nothing to say.
    ///
    /// Deliberately not `thinkingDoneText`: those two lines look identical and
    /// mean opposite things. "\u{2731} thought for 8s" is the machine reporting on
    /// work it just did and belongs in the theme's own ink; the idle phrase is
    /// the machine with nothing to report, and reads as noise in that same ink
    /// — a phosphor-green line that never goes away looks like a turn that
    /// never ends. So this one derives to a neutral grey: off, not speaking.
    case thinkingIdleText
}

/// Resolves every `ThemeRole` to a concrete `RGBAColor` for a given `ColorTheme`.
///
/// Resolution order per role: an explicit `ColorTheme.roleOverrides` entry wins;
/// otherwise the color is *derived* from the terminal palette by the default
/// mapping below (bg→window, fg→primary text, ANSI accents→semantic accents, and
/// luminance blends for surfaces/secondary text/borders). This is what lets a
/// plain terminal scheme drive app-wide chrome.
public struct SemanticPalette: Equatable, Sendable {
    public let theme: ColorTheme

    /// Every role resolved once at construction (override-or-derived), so repeated
    /// `color(_:)` lookups are O(1) dictionary reads. Resolving `secondaryText` /
    /// `tertiaryText` / `placeholderText` runs the iterative `dimmed()` contrast
    /// loop (pow-heavy); doing it per access in cell/draw/applyTheme paths is
    /// wasteful, so we pay it once per palette instance. Derived purely from
    /// `theme`, so it never breaks `Equatable`.
    private let resolved: [ThemeRole: RGBAColor]

    /// The runtime multiplier layered on top of `theme.typography.sizeScale`
    /// by `scaled(by:)`. Kept off `theme` itself — see `size(_:)` and
    /// `scaled(by:)` — so a reader's "Text Size" control never gets baked into
    /// the theme value this palette carries.
    private let readerScale: Double

    public init(theme: ColorTheme) {
        self.theme = theme
        self.readerScale = 1
        var map: [ThemeRole: RGBAColor] = [:]
        map.reserveCapacity(ThemeRole.allCases.count)
        for role in ThemeRole.allCases {
            map[role] = Self.resolve(role, theme: theme)
        }
        self.resolved = map
    }

    /// Backing initializer for `scaled(by:)`: reuses the already-resolved
    /// colors (scaling never touches color) and layers a new `readerScale` on
    /// top without disturbing `theme`.
    private init(theme: ColorTheme, resolved: [ThemeRole: RGBAColor], readerScale: Double) {
        self.theme = theme
        self.resolved = resolved
        self.readerScale = readerScale
    }

    /// The resolved color for `role` (override if present, else derived).
    public func color(_ role: ThemeRole) -> RGBAColor {
        resolved[role] ?? Self.resolve(role, theme: theme)
    }

    /// The effective point size for `role`: `theme.typography.size(role)` (the
    /// designer's own size × `sizeScale`) further multiplied by whatever
    /// `scaled(by:)` has layered on since. Font resolution reads this rather
    /// than `theme.typography.size(role)` directly — see `scaled(by:)` for why
    /// the two must not collapse into the same number.
    public func size(_ role: TextRole) -> Double {
        theme.typography.size(role) * readerScale
    }

    /// Whether the theme states this role outright, rather than leaving it to
    /// be derived from the terminal palette.
    ///
    /// For most roles the distinction does not matter — a derived surface is
    /// as good as a declared one. It matters where the *presence* of the
    /// element is the theme's decision rather than its colour: a bubble
    /// outline is drawn only by themes that ask for one, and every role
    /// derives to some opaque colour, so "is it visible" cannot answer "did
    /// the theme want it". Web draws the same line — `.pc-bubble` gets its
    /// `border: 1px solid var(--pc-persona-border)` from each theme's own
    /// stylesheet, and a theme that declares no such variable has no border
    /// rule at all.
    public func declares(_ role: ThemeRole) -> Bool {
        theme.roleOverrides[role.rawValue] != nil
    }

    /// The default palette-derived color for `role`, ignoring overrides.
    ///
    /// Backgrounds layer toward the foreground (so panels read above the window
    /// on both dark and light themes). Secondary/tertiary/placeholder text dim
    /// toward the backdrop but are held above legibility floors so even a
    /// low-contrast imported scheme stays readable. `onAccentText`/`selectionText`
    /// auto-pick black or white for contrast on their fills.
    public func derived(_ role: ThemeRole) -> RGBAColor {
        Self.derive(role, theme: theme)
    }

    /// Override-or-derived resolution for a single role.
    private static func resolve(_ role: ThemeRole, theme: ColorTheme) -> RGBAColor {
        theme.roleOverrides[role.rawValue] ?? derive(role, theme: theme)
    }

    private static func derive(_ role: ThemeRole, theme: ColorTheme) -> RGBAColor {
        let background = theme.background
        let foreground = theme.foreground
        switch role {
        case .windowBackground:
            return background
        case .surface:
            return background.blended(withFraction: 0.06, of: foreground)
        case .elevatedSurface:
            return background.blended(withFraction: 0.12, of: foreground)
        case .controlBackground:
            return background.blended(withFraction: 0.09, of: foreground)
        case .card:
            return derive(.elevatedSurface, theme: theme)
        case .primaryText:
            return foreground
        case .secondaryText:
            return foreground.dimmed(towards: background, by: 0.32, minContrast: 3.0)
        case .tertiaryText:
            return foreground.dimmed(towards: background, by: 0.55, minContrast: 2.0)
        case .placeholderText:
            return foreground.dimmed(towards: background, by: 0.68, minContrast: 1.6)
        case .onAccentText:
            return derive(.accent, theme: theme).bestTextColor()
        case .accent:
            return theme.ansiColor(at: 4) ?? foreground
        case .success:
            return theme.ansiColor(at: 2) ?? foreground
        case .warning:
            return theme.ansiColor(at: 3) ?? foreground
        case .danger:
            return theme.ansiColor(at: 1) ?? foreground
        case .info:
            return theme.ansiColor(at: 6) ?? foreground
        case .border:
            return background.blended(withFraction: 0.18, of: foreground)
        case .outline:
            return background.blended(withFraction: 0.30, of: foreground)
        case .divider:
            return background.blended(withFraction: 0.10, of: foreground)
        case .selection:
            return theme.selection
        case .selectionText:
            return theme.selection.bestTextColor()
        case .selectionEdge:
            return .clear
        case .cursor:
            return theme.cursor
        case .personaBubble:
            return background.blended(withFraction: 0.08, of: foreground)
        case .personaBubbleBorder:
            return background.blended(withFraction: 0.16, of: foreground)
        case .personaText:
            return foreground
        case .personaName:
            return derive(.accent, theme: theme)
        case .userBubble:
            return background.blended(withFraction: 0.18, of: derive(.accent, theme: theme))
        case .userBubbleBorder:
            return background.blended(withFraction: 0.34, of: derive(.accent, theme: theme))
        case .userText:
            return foreground
        case .userName:
            return foreground.dimmed(towards: background, by: 0.32, minContrast: 3.0)
        case .chatSurface:
            return background
        case .chatInputBackground:
            return background.blended(withFraction: 0.09, of: foreground)
        case .chatInputBorder:
            return background.blended(withFraction: 0.18, of: foreground)
        case .chatInputFocus:
            return derive(.accent, theme: theme)
        case .sendButton:
            return derive(.accent, theme: theme)
        case .sendButtonText:
            return derive(.accent, theme: theme).bestTextColor()
        case .sendButtonHover:
            return derive(.accent, theme: theme).blended(withFraction: 0.18, of: foreground)
        case .timestampText:
            return foreground.dimmed(towards: background, by: 0.55, minContrast: 2.0)
        case .thinkingDoneText:
            // Web's default is the literal `#8a8a8a`, and the *grey* is the
            // meaning: a turn that has stopped is no longer the live thing on
            // screen. Dimming the theme's ink without draining it kept the
            // hue, which on `old-school-terminal` settled a finished turn to a
            // slightly darker phosphor green that went on reading as running.
            // Derived rather than transcribed, for the reason `thinkingIdleText`
            // gives below: a fixed mid-grey washes out on a light theme. Dimmed
            // further than the idle line on purpose — that is web's extra
            // `opacity: 0.75` on `.pc-thinking--done`.
            return foreground.desaturated().dimmed(towards: background, by: 0.55, minContrast: 2.0)
        case .thinkingIdleText:
            // Grey by construction, not by transcription: the palette's own
            // ink with the colour drained out, then dimmed a quarter of the
            // way to the backdrop. That lands near the web library's literal
            // `#8a8a8a` on a dark theme without inheriting its failure on a
            // light one, and it is the one role in this table that must NOT
            // stay in the theme's hue -- a monochrome terminal has no grey in
            // its palette to derive from, which is exactly why the idle line
            // has to be given one.
            return foreground.desaturated().dimmed(towards: background, by: 0.25, minContrast: 3.0)
        }
    }

    /// An ordered list of visually distinct series colors for charts, guaranteed
    /// non-empty and to contrast against `surface` so no series collapses into
    /// the backdrop. The terminal "black"/"white" ANSI slots (0, 7, 8, 15) — which
    /// sit ~on the background on most themes — are deliberately excluded: leading
    /// with semantic accents, then the bright ANSI hues for additional variety.
    public var chartSeriesColors: [RGBAColor] {
        let surface = color(.surface)
        let semantic = [color(.accent), color(.success), color(.info), color(.warning), color(.danger)]
        let brights = [9, 10, 11, 12, 13, 14].compactMap { theme.ansiColor(at: $0) }
        let visible = (semantic + brights).filter { $0.contrastRatio(against: surface) >= 1.5 }
        return visible.isEmpty ? semantic : visible
    }

    /// An ordered list of hues for telling the MEMBERS of a set apart — the
    /// rings of a nested gauge, the series of a legend — in a view that ALSO
    /// colors by state.
    ///
    /// Distinct from `chartSeriesColors`, which leads with accent, success,
    /// warning and danger. Those four are exactly what such a view spends on
    /// meaning: a member painted `success` claims to be healthy and one painted
    /// `warning` claims to be in trouble, neither of which is what "this is the
    /// second one" means. So this list is drawn from the hues those four have
    /// not taken — magenta and cyan first, then their bright variants — and any
    /// candidate equal to one of them is dropped rather than merely
    /// deprioritized, so an identity color can never be read as a state.
    /// `info` is not excluded: it is a color for a NOTICE, which is a thing a
    /// view either draws or does not, never a standing a member is in.
    ///
    /// Filtered for contrast against `surface` so no member collapses into the
    /// card it is drawn on, and guaranteed non-empty: a theme whose ANSI table
    /// offers none of these falls back to `chartSeriesColors`, because two
    /// members in the same color still beat two members in no color at all.
    public var identitySeriesColors: [RGBAColor] {
        let surface = color(.surface)
        let spoken = [color(.accent), color(.success), color(.warning), color(.danger)]
        var hues: [RGBAColor] = []
        for slot in [5, 6, 13, 14] {
            guard let hue = theme.ansiColor(at: slot),
                  hue.contrastRatio(against: surface) >= 1.5,
                  !spoken.contains(hue),
                  !hues.contains(hue)
            else { continue }
            hues.append(hue)
        }
        return hues.isEmpty ? chartSeriesColors : hues
    }
}

extension SemanticPalette {
    public var windowBackground: RGBAColor { color(.windowBackground) }
    public var surface: RGBAColor { color(.surface) }
    public var elevatedSurface: RGBAColor { color(.elevatedSurface) }
    public var controlBackground: RGBAColor { color(.controlBackground) }
    public var card: RGBAColor { color(.card) }
    public var primaryText: RGBAColor { color(.primaryText) }
    public var secondaryText: RGBAColor { color(.secondaryText) }
    public var tertiaryText: RGBAColor { color(.tertiaryText) }
    public var placeholderText: RGBAColor { color(.placeholderText) }
    public var onAccentText: RGBAColor { color(.onAccentText) }
    public var accent: RGBAColor { color(.accent) }
    public var success: RGBAColor { color(.success) }
    public var warning: RGBAColor { color(.warning) }
    public var danger: RGBAColor { color(.danger) }
    public var info: RGBAColor { color(.info) }
    public var border: RGBAColor { color(.border) }
    public var outline: RGBAColor { color(.outline) }
    public var divider: RGBAColor { color(.divider) }
    public var selection: RGBAColor { color(.selection) }
    public var selectionText: RGBAColor { color(.selectionText) }
    public var selectionEdge: RGBAColor { color(.selectionEdge) }
    public var cursor: RGBAColor { color(.cursor) }
    public var personaBubble: RGBAColor { color(.personaBubble) }
    public var personaBubbleBorder: RGBAColor { color(.personaBubbleBorder) }
    public var personaText: RGBAColor { color(.personaText) }
    public var personaName: RGBAColor { color(.personaName) }
    public var userBubble: RGBAColor { color(.userBubble) }
    public var userBubbleBorder: RGBAColor { color(.userBubbleBorder) }
    public var userText: RGBAColor { color(.userText) }
    public var userName: RGBAColor { color(.userName) }
    public var chatSurface: RGBAColor { color(.chatSurface) }
    public var chatInputBackground: RGBAColor { color(.chatInputBackground) }
    public var chatInputBorder: RGBAColor { color(.chatInputBorder) }
    public var chatInputFocus: RGBAColor { color(.chatInputFocus) }
    public var sendButton: RGBAColor { color(.sendButton) }
    public var sendButtonText: RGBAColor { color(.sendButtonText) }
    public var sendButtonHover: RGBAColor { color(.sendButtonHover) }
    public var timestampText: RGBAColor { color(.timestampText) }
    public var thinkingDoneText: RGBAColor { color(.thinkingDoneText) }
    public var thinkingIdleText: RGBAColor { color(.thinkingIdleText) }
}

extension SemanticPalette {
    /// This palette with every font size multiplied by `factor`, *on top of*
    /// the theme's own `sizeScale`.
    ///
    /// The two scales answer to different people, so they must not be one
    /// number. A theme's `sizeScale` is the designer's: `old-school-terminal`
    /// sets 1.0667 because VT323 draws small for its point size, and that is a
    /// property of the typeface the theme picked, not a preference. `factor`
    /// is the reader's — the "Text Size" control — and has to survive a change
    /// of theme, which it does precisely because it is applied here rather
    /// than written into the theme.
    ///
    /// Clamped, because it arrives from a slider a host wires up: a scale of
    /// zero would lay the whole UI out at no height, taking every constraint
    /// built on an intrinsic size with it. Uses the same bound `ThemeStore`
    /// enforces on an imported theme's own declared scale — see
    /// `ThemeTypography.sizeScaleRange`.
    public func scaled(by factor: Double) -> SemanticPalette {
        let clamped = ThemeTypography.clampedSizeScale(factor)
        guard clamped != 1 else { return self }
        return SemanticPalette(theme: theme, resolved: resolved, readerScale: readerScale * clamped)
    }
}

/// The project window's resolved colors.
///
/// Each is read from more than one place — the pane view and the split view's
/// gutter both paint the backdrop, the workspace, the tabs and the theme editor
/// all draw the outline — so what each one resolves to lives here rather than
/// being spelled out at every site (`dry`).
extension SemanticPalette {

    /// The plane a project window's panes sit on: what shows through the frame
    /// spacing around them and the gutters between them. One step off
    /// `windowBackground`, which is what a pane itself paints, so the panes
    /// read as objects on a surface instead of one field cut by seams.
    public var projectPaneBackdrop: RGBAColor {
        theme.project?.paneBackdrop ?? elevatedSurface
    }

    /// The line around the project window's own shapes — the workspace and the
    /// tabs standing against it.
    ///
    /// The hairline tone, the same one the panes inside are drawn with: their
    /// title bars end in it and their dividers are a step fainter still. The
    /// workspace is the frame around all of that, so it is drawn as quietly as
    /// what it frames — `projectActivePaneOutline` is the colour reserved for
    /// saying *here*, and it says nothing if the frame is already shouting.
    public var projectPaneOutline: RGBAColor {
        theme.project?.paneOutline ?? border
    }

    /// The line around the pane the user is working in.
    ///
    /// The theme's accent: the one colour a theme nominates for exactly this,
    /// and the only place in the project window that earns it. Deliberately not
    /// a theme override of its own — a theme that recolours `paneOutline`
    /// restyles the frame, and the pane in front still stands out from whatever
    /// it chose.
    public var projectActivePaneOutline: RGBAColor { accent }
}
