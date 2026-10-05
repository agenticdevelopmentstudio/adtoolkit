
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `struct` conforming to `Codable`, `Sendable`, `Equatable` and `Comparable`, and mixed-currency operators use `precondition`.
- **Compose**: A `data class Money(val cents: Long, val currency: String = "USD")` with `operator` functions that `require` same currency; use `Long` to avoid overflow, and `BigDecimal` only at the formatting edge.
- **React/Web**: A class over `bigint` or a safe integer with `add`, `subtract` and `compare` that throw on mixed currencies; never use `number` fractions for the stored amount.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `readonly record struct Money(long Cents, string Currency = "USD")` with `operator +`, `-` and `IComparable<Money>` that throw `InvalidOperationException` on mixed currencies; use `long` hundredths and `decimal` only for display.

