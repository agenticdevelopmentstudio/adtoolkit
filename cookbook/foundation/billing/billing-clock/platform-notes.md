
- **SwiftUI**: Not used; the clock has no view layer.
- **Compose**: `java.time.ZonedDateTime` / `ZoneId.of`, falling back to `ZoneOffset.UTC` on `DateTimeException`.
- **React/Web**: `Intl.DateTimeFormat` with `timeZone` and `en-CA` for `YYYY-MM-DD`, or Temporal `ZonedDateTime`; catch the `RangeError` for an unknown zone and use `UTC`.
- **AppKit / UIKit**: Foundation `TimeZone(identifier:)` with a `TimeZone(identifier: "UTC")` fallback; the day string comes from the shared `UTCTimestamp.day(of:in:)`.
- **WinUI 3**: `TimeZoneInfo.FindSystemTimeZoneById` (IANA ids resolve on Windows through ICU in .NET 6+), falling back to `TimeZoneInfo.Utc` when it throws `TimeZoneNotFoundException`; format with `ToString("yyyy-MM-dd")`.

