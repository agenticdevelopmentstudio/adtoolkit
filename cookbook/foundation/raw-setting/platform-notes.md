
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum` with three static functions.
- **Compose**: Top-level functions `rawBool`, `rawInt` and `rawString` using `trim().lowercase()` and `coerceIn`.
- **React/Web**: Three pure functions; use `Number.parseInt` only after a `/^-?\d+$/` check, because `parseInt('12abc')` would accept trailing text.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers using `string.Trim()`, `int.TryParse` with `NumberStyles.Integer` and `CultureInfo.InvariantCulture`, and `Math.Clamp`; read raw text from `ApplicationData` settings or environment variables.

