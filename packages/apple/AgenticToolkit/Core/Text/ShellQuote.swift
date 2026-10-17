import Foundation

/// One spelling of shell quoting for every command Stenographer writes into
/// `settings.json` or a claudehelpers status-line entry, matching Python's
/// `shlex.quote` so claudehelpers' Python and this code write identical
/// strings for the same path.
public enum ShellQuote {

    private static let safe = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@%+=:,./-")

    /// The word unchanged when it is non-empty and made only of
    /// `[A-Za-z0-9_@%+=:,./-]`, else wrapped in single quotes with each embedded
    /// `'` written as `'"'"'`. The replace is `.literal`: the default compares
    /// by grapheme, so a `'` followed by a combining mark (U+0301) would go
    /// unescaped and break the quoting.
    public static func word(_ word: String) -> String {
        if !word.isEmpty, word.unicodeScalars.allSatisfy(safe.contains) { return word }
        return "'" + word.replacingOccurrences(of: "'", with: "'\"'\"'", options: .literal) + "'"
    }
}
