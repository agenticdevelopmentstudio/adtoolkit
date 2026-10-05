
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It uses two `ISO8601DateFormatter` instances held as `nonisolated(unsafe)` statics and a `DateFormatter` with a POSIX locale and a UTC zone for the SQLite shape.
- **Compose**: Use `java.time.Instant.parse` for the two ISO shapes and a `DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").withZone(UTC)` for SQLite; `OffsetDateTime.parse` accepts numeric offsets.
- **React/Web**: `Date.parse` accepts the ISO shapes but treats the space-separated form as local time in some engines; normalize the SQLite shape by replacing the space with `T` and appending `Z` before parsing.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: `DateTimeOffset.TryParse` with `DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal` and `CultureInfo.InvariantCulture` handles all three shapes; use `TryParseExact` for the SQLite pattern to avoid locale guesses.

