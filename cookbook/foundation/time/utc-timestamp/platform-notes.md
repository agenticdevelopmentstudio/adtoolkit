
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with private helpers for Hinnant's civil-date algorithms and `String(format:)` for the fixed-width output.
- **Compose**: `java.time.Instant` with `DateTimeFormatter.ISO_INSTANT` truncated to seconds covers writing; the civil-day algorithms are unnecessary on the JVM, but the validation rules and the SQLite millisecond form still need a pure parser.
- **React/Web**: `new Date(s * 1000).toISOString().slice(0, 19) + 'Z'` writes the wire form; a regex-free fixed-width reader over character codes is the fast path, falling back to `Date.parse`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: `DateTimeOffset.ToUnixTimeSeconds` and `FromUnixTimeSeconds` write and read whole seconds; `ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture)` writes the form, and `TimeZoneInfo.GetUtcOffset` supplies the offset for day keys.

