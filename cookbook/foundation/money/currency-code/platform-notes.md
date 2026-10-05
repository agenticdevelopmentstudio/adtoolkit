
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with one static function.
- **Compose**: A top-level function using `trim().uppercase()` and a `Regex("[A-Z]{3}")` full match; `java.util.Currency.getInstance` would also check membership, which this rule deliberately does not.
- **React/Web**: A pure function `text.trim().toUpperCase()` tested against `/^[A-Z]{3}$/`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A static helper using `Trim().ToUpperInvariant()` and a check that all three characters are in the range `A` to `Z`; use the invariant culture so the Turkish dotless-i rule cannot change the result.

