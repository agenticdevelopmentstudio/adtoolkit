import Foundation

/// What the frontmost window says it is showing: a document on disk, or an
/// address on the network.
///
/// macOS hands both back through the same Accessibility attribute
/// (`kAXDocumentAttribute`) — Xcode answers with a `file://` URL, Chromium
/// browsers answer with the page's `https://` URL — so something has to
/// decide which of the two a given string is. That decision is this type,
/// and it is deliberately free of any Accessibility API: Windows' UIA and
/// Android's accessibility tree present the same ambiguity, and the rule
/// that resolves it should not have to be written a second time to be
/// reused there.
///
/// The split matters downstream. Both used to land in one `document_path`
/// column, which made "what files did I work on today" answer with a list
/// of web pages.
public enum WindowAddress: Equatable, Sendable {
    /// A path on the local filesystem, with any `file://` wrapper removed.
    case file(String)
    /// A network address, kept verbatim in whatever form the app reported it.
    case url(String)

    public var filePath: String? {
        if case .file(let p) = self { return p }
        return nil
    }

    public var urlString: String? {
        if case .url(let u) = self { return u }
        return nil
    }

    /// Classifies a raw window-document string, or returns `nil` when the app
    /// exposed nothing.
    ///
    /// A `file://` URL is unwrapped to its path, because that is the form the
    /// rest of the system — `FileManager`, the document-metadata reader, the
    /// user reading a timeline row — actually speaks. Any other scheme makes
    /// it a URL. Everything else is taken as a path: an app that answers with
    /// a bare `/Users/…` is describing a file, and so is one that answers with
    /// a filename alone.
    ///
    /// Note for schema work: migration 8's backfill splits the historical
    /// `document_path` column with the same test (`'%://%'`, minus the
    /// `file://` case that never reached the column). Keep them in step.
    public init?(rawDocument raw: String?) {
        guard let raw, !raw.isEmpty else { return nil }
        if raw.hasPrefix("file://") {
            // `URL(string:)` is what percent-decodes `%20` back to a space;
            // falling back to the raw string keeps a malformed URL rather
            // than dropping the only identity the window had.
            self = .file(URL(string: raw)?.path ?? raw)
        } else if raw.contains("://") {
            self = .url(raw)
        } else {
            self = .file(raw)
        }
    }
}
