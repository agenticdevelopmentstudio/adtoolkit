
- **SwiftUI**: Labels feed `Picker` and list rows; no SwiftUI types appear here.
- **Compose**: Data class `copy(...)` with a nullable-wrapper (`Optional<T>`) for clearable fields.
- **React/Web**: Spread-copy (`{...record, ...changes}`) with `null` as the clear value.
- **AppKit / UIKit**: Extensions on the immutable DTOs; the double-optional `Int??` distinguishes omit from clear.
- **WinUI 3**: C# `record` types with `with` expressions; `decimal.TryParse` with `CultureInfo.CurrentCulture` for rate text, then convert to cents.

