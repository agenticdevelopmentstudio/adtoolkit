
- **Decision**: The header icon's color maps file-extension "brand" associations onto the theme's status roles: `swift`/`json` land on `warning`, `md`/`markdown` on `accent`.
  **Rationale**: `headerIconColor`'s own source comment (`ContentViewerView.swift`) draws this as an analogy to `SwiftUIPalette.color(named:)`'s conventional-color-to-role mapping used elsewhere in the toolkit (orange/yellow → `warning`, blue → `accent`) — `headerIconColor` itself switches directly on the file extension rather than calling that mapping function, so `swift`/`json` landing on `warning` and `md`/`markdown` landing on `accent` mirrors, but does not literally reuse, that shared mapping.
  **Approved**: pending

- **Decision**: A stale "Items:" row — showing a `children` count that no longer matches the node's current, asynchronously-updated value — is treated as a known limitation of this SwiftUI implementation (see the **Concurrent access** edge case), not a contract other platform implementations are required to reproduce.
  **Rationale**: The staleness is a side effect of `FileDetailView` holding `node` as a plain `let` rather than observing it (`@ObservedObject`); nothing in source suggests this was an intentional design choice rather than an oversight, so it should not be codified as required behavior for a port to copy.
  **Approved**: pending

- **Decision**: Each metadata grid row keeps its label and value as two separate `Text` elements — e.g. two accessibility elements for "Path:" and its value — rather than combining them with `.accessibilityElement(children: .combine)`.
  **Rationale**: Not stated in source: no accessibility modifier is applied to any `GridRow` or `Text` in `ContentViewerView.swift`, so each `Text` keeps SwiftUI's default per-element accessibility behavior. Combining each row into one spoken utterance (e.g. "Path: /Users/x/a.txt") would need `.accessibilityElement(children: .combine)` added to each `GridRow`, which the source does not do; a port needs to decide whether to copy the current split behavior or add the combine modifier.
  **Approved**: pending

- **Decision**: No explicit accessibility change notification is posted when `selectedNode` changes and the `Group`'s content is replaced.
  **Rationale**: Not stated in source: `ContentViewerView.swift` contains no accessibility-notification call anywhere. Whatever announcement (if any) a VoiceOver user hears on selection change comes entirely from SwiftUI/AppKit's own automatic change detection (see the Accessibility section's Announce state changes item); a port needs to decide whether that is sufficient or whether an explicit notification should be added.
  **Approved**: pending

- **Decision**: `byteCountFormatter` and `dateFormatter` are declared as `static let` constants on `FileDetailView` rather than being created inside `body`.
  **Rationale**: A `static let` is created once and reused for every re-evaluation of `body` and for every `FileDetailView` instance, instead of allocating a fresh `ByteCountFormatter`/`DateFormatter` on each render.
  **Approved**: pending

- **Decision**: The placeholder icon (48pt) and the header icon (40pt) are sized with literal `Image(...).font(.system(size:))` calls rather than `theme.font(_:)`.
  **Rationale**: Not stated in source. The observable effect is that both icons stay a fixed point size regardless of the theme's `sizeScale` text-size preference, while every text element in this view (which does call `theme.font(_:)`) scales with it.
  **Approved**: pending

