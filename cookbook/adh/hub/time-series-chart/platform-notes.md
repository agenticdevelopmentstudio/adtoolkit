
- **React/Web (source)**: `packages/web/packages/adh-ui/src/components/time-series-chart.tsx`
  (`"use client"`), built on the `recharts` library: a responsive container
  wrapping a line chart with a cartesian grid, x and y axes, a tooltip, an
  optional legend, and one line per series. The y axis is 72 pixels wide and
  the x axis spaces ticks at least 24 pixels apart. Colours are CSS custom
  properties (`--color-apt-cat-*` for the series, `--color-apt-text-dim`,
  `--color-apt-border`, `--color-apt-surface-2`, `--color-apt-text`,
  `--color-apt-text-muted`, `--color-apt-bg`), each series colour with a
  literal fallback. Lines use monotone interpolation with null gaps not
  connected.
- **SwiftUI**: Use Swift Charts: a `Chart` containing one `LineMark` per point
  per series, with `.foregroundStyle(by:)` bound to the series label for the
  automatic legend, `.interpolationMethod(.monotone)`, and `chartYAxis` with an
  `AxisValueLabel` using the format function. A missing value is simply an
  omitted mark, which Swift Charts draws as a break. The crosshair tooltip is a
  `chartOverlay` with a `DragGesture` and a `RuleMark`.
- **Compose**: Draw with a charting library such as Vico (a `CartesianChartHost`
  with a `LineCartesianLayer`) or a hand-written `Canvas` that splits each
  series into path segments at null values. The tooltip is a marker bound to
  the touch or hover position; supply the four palette colours as a fixed list
  indexed by series position.
- **AppKit/UIKit**: Use Swift Charts through `NSHostingView` or
  `UIHostingController`, or a custom `CAShapeLayer` per series with one path
  per contiguous non-null run; place a `NSTrackingArea` or
  `UIHoverGestureRecognizer` to drive the crosshair and tooltip.
- **WinUI 3**: Use a charting control such as the WinUI-compatible
  LiveCharts2 `CartesianChart` (or the Windows Community Toolkit's chart
  controls) with one `LineSeries` per series: set `GeometrySize` to 0 to draw
  no per-point dots, `LineSmoothness` to a non-zero value for the monotone look,
  and leave null values in the `ObservableCollection` of nullable doubles so the
  line breaks at the gap. Assign the four palette colours from a
  `ThemeDictionaries` brush resource so they follow light and dark themes, set
  `AnimationsSpeed` to zero to match the no-animation requirement, and show the
  `Legend` only when the `Series` count is two or more. The tooltip is the
  control's built-in tooltip bound to a `DataTemplate` that prints the label and
  the formatted value, or an em dash for a null; bind the y axis `Labeler` to the
  format function. Throw an `ArgumentOutOfRangeException` from the view-model
  setter when more than four series are supplied.

