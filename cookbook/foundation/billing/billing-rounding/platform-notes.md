
- **SwiftUI**: Not used; the function has no view layer.
- **Compose**: A top-level or companion function over `Int`; use `Math.ceil`-style integer arithmetic, not floating point.
- **React/Web**: A pure function over `number`; use `Math.ceil` and `Math.floor(x + 0.5)` on integers, never fractional minutes.
- **AppKit / UIKit**: Plain Swift; the mode string is mapped through `IncrementRounding(rawValue:)` with `.upward` as the default.
- **WinUI 3**: A static method over `int` / `long`; use integer division and `Math.DivRem`, not `double`, to avoid rounding drift.

