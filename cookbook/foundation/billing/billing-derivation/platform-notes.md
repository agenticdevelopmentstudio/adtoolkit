
- **SwiftUI**: Not used; the function has no view layer.
- **Compose**: A pure function over `List<Long>`; reuse a shared activity-run splitter.
- **React/Web**: A pure function over `number[]`; use `Date.parse` or Temporal for timestamps.
- **AppKit / UIKit**: Foundation-only; splitting is delegated to the shared `ActivityRuns.split` and timestamp handling to `UTCTimestamp`.
- **WinUI 3**: A static method over `long` seconds; `DateTimeOffset.TryParse` for inputs; `IReadOnlyList<BillingRun>` result.

