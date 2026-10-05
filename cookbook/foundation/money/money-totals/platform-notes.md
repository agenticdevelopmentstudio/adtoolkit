
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a `struct` conforming to `Equatable` and `Sendable` with `private(set)` buckets, built from `some Sequence<Money>`.
- **Compose**: A class over `sortedMapOf<String, Long>()` with `add(Money)` and `toString()` delegating to the formatter per currency.
- **React/Web**: A class over a `Map<string, number>` of integer hundredths, with `currencies()` returning `[...map.keys()].sort()`.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: A `SortedDictionary<string, long>` wrapper with `Add(Money)` and `ToString()`; bind a `TextBlock.Text` to the description property in a billing summary.

