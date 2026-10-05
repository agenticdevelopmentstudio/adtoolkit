
- **SwiftUI**: The source file imports only `Foundation`; nothing in it is SwiftUI-specific, so a SwiftUI host uses it unchanged from any view model or store. It is a caseless `enum`; `String(format:)` pads the minutes, seconds and decimal fraction.
- **Compose**: Top-level functions using integer arithmetic and `String.format("%d:%02d:%02d")`; the localized duration APIs (`DateUtils.formatElapsedTime`) do not give the decimal-hours form.
- **React/Web**: Pure functions using integer `Math.floor` and string padding; never divide seconds by 3600 as a float for the decimal form.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic, and only the embedding application differs, never this contract.
- **WinUI 3**: Static helpers using `int` arithmetic and `ToString("D2")`; a `TextBox` bound to a duration can call the parser on `LostFocus` and keep the old value when it returns null.

