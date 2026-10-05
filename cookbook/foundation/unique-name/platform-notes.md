
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; folding uses `folding(options: [.caseInsensitive], locale: nil)`.
- **Compose**: Top-level functions over `Iterable<String>`; build a `HashSet` once and use `trim().lowercase()` for the collision check.
- **React/Web**: Pure functions over `Iterable<string>` using a `Set`; `trim().toLowerCase()` or `localeCompare` with `sensitivity: 'accent'` for the fold.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers over `IEnumerable<string>` with a `HashSet<string>` for the search and `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` after `Trim()` for the collision check.

