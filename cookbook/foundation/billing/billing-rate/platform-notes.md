
- **SwiftUI**: Not used; the type has no view layer.
- **Compose**: A pure function over data classes; `firstOrNull` replaces `first(where:)`.
- **React/Web**: A pure function over plain objects; `Array.prototype.find` replaces `first(where:)`.
- **AppKit / UIKit**: Plain Swift over `BillingRepoDTO` and `BillingProjectDTO`; results are `Sendable` and `Equatable`.
- **WinUI 3**: Static methods over record types; use `FirstOrDefault` with a null check and `int?` for nullable cents.

