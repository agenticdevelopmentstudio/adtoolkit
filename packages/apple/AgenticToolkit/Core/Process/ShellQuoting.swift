import Foundation

/// Quoting for a POSIX shell, so a word reaches the command as exactly one
/// argument whatever it holds. The spelling matches Python's `shlex.quote`,
/// so claudehelpers' Python and this code write identical strings for the
/// same path in `settings.json` and status-line entries.
public enum ShellQuoting {

    /// `word` single-quoted, each embedded `'` written as `'"'"'`. The replace
    /// is `.literal`: the default compares by grapheme, so a `'` followed by a
    /// combining mark (U+0301) would go unescaped and break the quoting.
    public static func quote(_ word: String) -> String {
        "'" + word.replacingOccurrences(of: "'", with: "'\"'\"'", options: .literal) + "'"
    }

    /// `word` as is when it is non-empty and made only of
    /// `[A-Za-z0-9_@%+=:,./-]`, and ``quote(_:)`` otherwise, so a plain
    /// command line stays readable.
    public static func quoteIfNeeded(_ word: String) -> String {
        let isPlain = !word.isEmpty && word.unicodeScalars.allSatisfy(plain.contains)
        return isPlain ? word : quote(word)
    }

    /// The words as one command line that a shell splits back into the same words.
    public static func commandLine(_ words: [String]) -> String {
        words.map(quoteIfNeeded).joined(separator: " ")
    }

    private static let plain = CharacterSet(charactersIn:
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_@%+=:,./-")
}
