
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. Display uses `Decimal.formatted(.currency(code:).precision(...).locale(...))`, and parsing rounds with `NSDecimalRound(.plain)`.
- **Compose**: Use `NumberFormat.getCurrencyInstance(locale)` with `setMinimumFractionDigits(2)` and `setMaximumFractionDigits(2)` and `BigDecimal` for parsing; reimplement the separator rules in a pure function because `NumberFormat.parse` accepts partial strings.
- **React/Web**: `Intl.NumberFormat(locale, {style: 'currency', currency, minimumFractionDigits: 2, maximumFractionDigits: 2})` for display, with the integer divided by 100 via string arithmetic, not a float; port the parse rules as a pure function using `Intl.NumberFormat().formatToParts` to learn the locale's separators.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Use `decimal` with `ToString("C2", cultureInfo)` and `NumberFormatInfo.NumberDecimalSeparator`/`CurrencyGroupSeparator` to learn the locale's separators; a `TextBox` with a `TextChanging` handler can call the parser and keep the last good value when it returns null.

