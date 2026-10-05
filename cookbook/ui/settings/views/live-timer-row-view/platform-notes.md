
- **SwiftUI**: A `TimelineView(.periodic(from:by:1))` supplies the tick; format with `Text(timerInterval:)` or a duration formatter.
- **Compose**: A `LaunchedEffect` loop with `delay(1000)` updating a `produceState` clock; the row is a `Row` with a weighted, ellipsizing `Column`.
- **React/Web**: A `setInterval` hook (clear on unmount) and `font-variant-numeric: tabular-nums`; the title uses `text-overflow: ellipsis`.
- **AppKit / UIKit (source)**: `ComposableSettings.LiveTimerRowView` is an `@MainActor` `NSView` with a nested `Model` (`Equatable`, `Sendable`), `ThemedLabel`s for origin, title, subtitle and elapsed (the `.code` text role), and an `NSButton` stop control with the `stop.fill` symbol. Title and subtitle compression resistance is 499, below the labels' hugging. The clock uses `DurationFormatter.clock(seconds:)`. `LiveTimerTicker` is an `@MainActor` class using a `Timer` added to `RunLoop.main` in `.common` mode with tolerance one tenth of the interval; `fireForTests()` delivers one tick synchronously.
- **WinUI 3**: A grid with `TextBlock`s and a `Button` with a `SymbolIcon`; drive the clock with a `DispatcherTimer` and truncate with `TextTrimming="CharacterEllipsis"`.

