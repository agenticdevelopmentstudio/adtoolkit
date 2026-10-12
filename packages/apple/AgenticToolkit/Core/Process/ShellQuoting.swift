import Foundation

/// Quoting for a POSIX shell, so a word reaches the command as exactly one
/// argument whatever it holds.
public enum ShellQuoting {

    /// `word` single-quoted, its own single quotes closed and escaped.
    public static func quote(_ word: String) -> String {
        "'" + word.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// `word` as is when no character in it means anything to the shell, and
    /// ``quote(_:)`` otherwise, so a plain command line stays readable.
    public static func quoteIfNeeded(_ word: String) -> String {
        let plain = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "@%+=:,./-_"))
        let isPlain = !word.isEmpty && word.unicodeScalars.allSatisfy { $0.isASCII && plain.contains($0) }
        return isPlain ? word : quote(word)
    }

    /// The words as one command line that a shell splits back into the same words.
    public static func commandLine(_ words: [String]) -> String {
        words.map(quoteIfNeeded).joined(separator: " ")
    }
}
