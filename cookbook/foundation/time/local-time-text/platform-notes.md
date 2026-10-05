
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It uses `DateFormatter` with `dateFormat(fromTemplate:)` for the locale's month-day order and a `Cache` class marked `@unchecked Sendable` with an `NSLock`.
- **Compose**: Use `DateTimeFormatter.ofLocalizedTime` and `DateFormat.is24HourFormat`; parse with several `DateTimeFormatter` patterns in order and `ZonedDateTime` for the nearest-instant search.
- **React/Web**: `Intl.DateTimeFormat(locale, {hour: 'numeric', minute: '2-digit', timeZone})` and `resolvedOptions().hour12` for the classification; cache formatters in a `Map` keyed by `pattern|zone|locale`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use `CultureInfo.DateTimeFormat.ShortTimePattern` to classify the clock, `DateTime.TryParseExact` with an explicit pattern list for entry, and `TimeZoneInfo` for the zone; bind a `TimePicker` or `TextBox` and call the parser on commit.

