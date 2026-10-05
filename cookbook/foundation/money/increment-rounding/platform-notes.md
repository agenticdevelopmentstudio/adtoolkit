
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `String`-backed `enum` conforming to `Sendable` and `CaseIterable`, with a `round` method.
- **Compose**: An `enum class` with a `round(value, increment)` function using integer division; keep `Int` or `Long` arithmetic.
- **React/Web**: A string union `'up' | 'nearest'` and a pure function using `Math.trunc` division on integers.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: An `enum IncrementRounding { Upward, Nearest }` with an extension method `Round(int value, int increment)` using integer arithmetic only; avoid `Math.Round`, whose default is banker's rounding.

