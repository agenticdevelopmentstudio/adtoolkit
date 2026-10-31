import Foundation

extension BuiltInThemes {
    /// The web-ported themes as the native app ships them: each generated
    /// theme with its native-only adjustments applied.
    ///
    /// `BuiltInThemes+Web.swift` is generated from the web CSS and must not be
    /// hand-edited, and the web catalogue has no tokens for the native chrome
    /// these touch (the selection fill, cards, the project window's plane). So
    /// the adjustments live here, applied over the generated values, and a
    /// re-run of the generator cannot silently drop them.
    static let webPortedNative: [ColorTheme] = webPorted.map(nativeAdjusted)

    static func nativeAdjusted(_ theme: ColorTheme) -> ColorTheme {
        switch theme.id {
        case fishlamp.id: return fishlampNative(theme)
        default: return theme
        }
    }

    /// Fishlamp's generated chrome put three things on one warm grey-brown:
    /// the selection (amber at 30% over near-black), the cards and settings
    /// groups, and the pane title bars. The selection becomes a cool slate with
    /// an amber line marking it, and cards and the plane the panes sit on drop
    /// below the title bars to the theme's own `#17130f`, so the title bars are
    /// the only thing left on that grey.
    private static func fishlampNative(_ theme: ColorTheme) -> ColorTheme {
        var theme = theme
        let ember = RGBAColor(hexString: "#17130fff")!
        theme.selection = RGBAColor(hexString: "#232831ff")!
        theme.roleOverrides[ThemeRole.card.rawValue] = ember
        theme.roleOverrides[ThemeRole.selectionEdge.rawValue] = RGBAColor(hexString: "#e8a33dff")!
        theme.project = ThemeProjectOptions(paneBackdrop: ember)
        return theme
    }
}
