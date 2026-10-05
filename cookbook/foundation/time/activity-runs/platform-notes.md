
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. The algorithms are generic over `Comparable` and `AdditiveArithmetic` stamps inside a caseless `enum`, with a conditional `Sendable` conformance.
- **Compose**: Use generics `T : Comparable` with a `minus` function parameter where Kotlin's lack of `AdditiveArithmetic` requires one; `data class Span<T>` and a `Splitter` class.
- **React/Web**: Write the algorithms over `number` stamps; the union can be generic with a comparator function so ISO strings sort lexically.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A generic `Span<T> where T : IComparable<T>` record and a `Splitter<T>` that takes a `Func<T, T, T>` subtraction; for `DateTimeOffset` stamps use `TimeSpan` gaps.

