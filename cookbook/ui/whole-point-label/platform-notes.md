
- **SwiftUI**: Rarely needed: SwiftUI sizes `Text` itself; if a hosted label clips, apply `.fixedSize()` or round the measured width up in a custom `Layout`.
- **Compose**: Compose `Text` rounds to whole pixels; if a custom measurement clips, use `ceil` on the measured width in a `Layout` modifier.
- **React/Web**: Measure with `getBoundingClientRect` and set `Math.ceil(width) + 'px'` as the element's min-width.
- **AppKit / UIKit (source)**: `WholePointLabel` is a public final `NSTextField` subclass overriding `intrinsicContentSize` to return `ceil(width)` with the same height and passing `NSView.noIntrinsicMetric` through. `DisclosureCardView` uses it for its title field.
- **WinUI 3**: Round up the measured width in `MeasureOverride` with `Math.Ceiling` and return that desired size from a custom `TextBlock` host.

