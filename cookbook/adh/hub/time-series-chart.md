---
id: f571e2ee-ce27-4405-9e79-f69f601f9e1f
title: "Time Series Chart"
domain: adtoolkit://cookbook/adh/hub/time-series-chart
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-10-04
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A thin multi-series line chart over time on one shared y scale, with a crosshair tooltip, a legend once there are two or more series, and a fixed four-colour categorical palette assigned by series position."
platforms:
  - typescript
  - web
tags:
  - component
  - chart
  - data-visualization
  - ui
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Time Series Chart

## Overview

The Time Series Chart draws a handful of series as thin lines across a shared
sequence of x positions (days, weeks, months), all on ONE y scale. Two measures
of different scale belong in two charts, never on a second axis. A crosshair
tooltip reads every series at the hovered x position, and a legend names the
series once there are two or more, so a series is never identified by colour
alone. A missing value is a gap in the line, never a zero. The chart draws at
most four series, each coloured by its position in the series list from a fixed
categorical palette that is stable across themes; a fifth series is refused
rather than given a generated hue a reader could no longer tell apart (the
caller folds the tail into an "Other" series instead). The plot's width follows
its container; only the height is a parameter.

## Behavioral Requirements

- **draws-one-line-per-series**: The component MUST draw exactly one line for
  each entry in the series list, reading each line's values from the point key
  named by that series.
- **x-label-from-point**: The component MUST place each point at the x position
  labelled by that point's `x` value, in the order the points are given.
- **gap-for-null-value**: A point whose value for a series is `null` MUST be
  drawn as a break in that series' line and MUST NOT be drawn as a zero; the
  line MUST NOT be connected across the gap.
- **single-y-scale**: All series MUST share one y axis; the component MUST NOT
  offer a second axis.
- **series-colour-by-position**: A series MUST take its colour from a fixed
  ordered palette of four categorical colours by its position in the series
  list (first blue, second orange, third violet, fourth pink), never by its
  rank in the data.
- **palette-tokens-with-fallback**: Each palette colour MUST be read from a
  theme token with a literal fallback value, so the colour is hue-stable across
  themes.
- **refuses-fifth-series**: The component MUST refuse a series list longer than
  the palette (more than four) by raising a range error naming the limit and the
  count received, and MUST NOT draw a chart in that case.
- **legend-from-two-series**: The component MUST show a legend naming every
  series when there are two or more series, and MUST NOT show a legend for a
  single series.
- **legend-uses-series-label**: Each series' line, legend entry, and tooltip row
  MUST be named by that series' `label`, not its `key`.
- **crosshair-tooltip**: The component MUST show a tooltip, with a crosshair
  cursor, that lists every series' value at the hovered x position under that
  x label.
- **format-applies-to-axis-and-tooltip**: The component MUST pass every numeric
  value shown on the y axis and in the tooltip through the caller's format
  function, which defaults to rendering the number as-is.
- **tooltip-null-placeholder**: The tooltip MUST render a value that is not a
  number as an em dash, and MUST NOT pass it to the format function.
- **height-parameter**: The component MUST render the plot at the given height
  in pixels, defaulting to 240, and MUST size the plot's width to its container.
- **no-point-dots**: Lines MUST be drawn without a dot on every point; only the
  hovered point MAY show an enlarged marker.
- **no-animation**: The component MUST draw its lines without an entrance
  animation.
- **themed-by-tokens**: Axis text, grid lines, tooltip surface, tooltip border,
  and tooltip text MUST take their colours from theme tokens rather than literal
  colours.
- **horizontal-grid-only**: The grid MUST draw horizontal lines only, at reduced
  opacity.
- **no-mutable-state**: The component MUST hold no state of its own; it MUST
  render only from its inputs.

## Appearance

The chart's visual treatment is set entirely by the component and theme tokens.

- **Corner radius**: only the tooltip, at 8px; the plot itself has none.
- **Padding**: the plot has margins of 8px top, 16px right, 0 bottom, 8px left; the y axis reserves 72px of width.
- **Font**: axis ticks use 12px text in the dim-text token; the legend uses 12px text in the muted-text token.
- **Background**: the plot is transparent; the tooltip uses the second surface token.
- **Foreground/Text**: tooltip rows use the text token and the tooltip's x label the muted-text token.
- **Border**: the tooltip has a 1px border in the border token; the x axis has a baseline in the border token; the y axis has no axis line; ticks have no tick marks.
- **Shadow**: none.
- **Min/Max size**: width is 100 percent of the container; height is the height input, default 240px. Lines are 2px wide; the hovered point's marker has a radius of 4px with a 2px outline in the background token.

## States

| State | Appearance change |
|-------|------------------|
| Default | Lines, grid, axes drawn; no tooltip |
| Single series | No legend |
| Two or more series | Legend below the plot, one plain-line icon and label per series |
| Hovered x position | Crosshair line in the border token and a tooltip listing every series at that x |
| Null value | Break in that series' line |
| Disabled | Not applicable: the chart has no interactive control to disable; its interaction is pointer hover (and the chart library's default arrow-key navigation). |
| Pressed | Not applicable: the chart has no pressable element. |
| Loading | Not applicable: the source has no async operation or loading flag; the caller supplies points synchronously. |
| Error | A series list longer than four raises a range error instead of rendering (see refuses-fifth-series). |

## Accessibility

- Role: the component sets no role, label, or text alternative of its own and does not disable the chart library's default accessibility layer (the library, at the version the package depends on, defaults it on), so the plot is exposed by the library as an application region; the legend and axis tick labels are text a screen reader can reach.
- Label requirement: not satisfied — the component accepts no accessible-name input and passes no title to the chart.
- Keyboard: provided by the chart library's default accessibility layer rather than by the component — the plot is focusable and the left and right arrow keys move the tooltip between x positions; the component adds no keyboard path of its own.
- Differentiate without color: satisfied for identity when there are two or more series, because the legend and tooltip name each series (see legend-from-two-series); the lines themselves differ only by colour.
- Contrast: all colours are theme tokens, and the component performs no contrast check of its own; whether the series colours meet a minimum contrast ratio against the page background depends on the resolved token values.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | draws-one-line-per-series, legend-from-two-series, legend-uses-series-label | three points; series `direct` ("Direct") and `fixed` ("Fixed") (test: draws one line per series with a legend naming each) | Two line paths render; the labels "Direct" and "Fixed" appear |
| T2 | series-colour-by-position, palette-tokens-with-fallback | the same two series (test: colours series by position in the fixed order) | The first line's stroke is the blue token with fallback `#2f80ff`; the second's is the orange token with fallback `#f6821f` |
| T3 | legend-from-two-series | one series only (test: shows no legend for a single series) | One line path renders and no legend element exists |
| T4 | format-applies-to-axis-and-tooltip | one series, format function that prefixes "v" (test: formats y-axis ticks with the given formatter) | At least one y-axis tick reads "v" followed by digits |
| T5 | refuses-fifth-series | five series with keys a, b, c, d, e (test: refuses more series than it has colours) | Rendering throws a range error |
| T6 | gap-for-null-value | a point with `null` for `direct` between two numeric points | The `direct` line breaks at that x; no value of zero is plotted there |
| T7 | tooltip-null-placeholder | hover the x position whose `direct` value is `null` | The tooltip shows an em dash for Direct and the formatted number for Fixed |
| T8 | height-parameter | no height given | The plot renders 240 pixels high |
| T9 | series-colour-by-position | four series | Strokes are blue, orange, violet, pink in series order |
| T10 | refuses-fifth-series | five series | The error message names a limit of 4 and a count of 5 |

## Edge Cases

- **Null/empty input**: an empty points list or an empty series list draws no
  lines; the source performs no check for either. A `null` value is a gap, not
  a zero (see gap-for-null-value, T6).
- **Boundary values**: exactly four series is the maximum accepted; five is
  refused (see refuses-fifth-series, T5/T10). A single series is accepted and
  shows no legend (T3).
- **Concurrent access**: not applicable; the component holds no state and
  renders purely from its inputs (see no-mutable-state).
- **Error states**: the only error the component raises is the range error for
  more series than the palette holds; it is raised before anything is drawn.
  Where the plot's container measures zero by zero, nothing is drawn — the
  test file mocks the measured box for exactly this reason.
- **Offline / disconnected**: not applicable; the component makes no network
  call and receives its points from the caller.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `points` | read-only list of points | — | Each point has an `x` label and one numeric-or-null value per series key. |
| `series` | read-only list of series | — | Each series has a `key` (the point key it reads) and a `label`; at most four. |
| `format` | function from number to string | the number as-is | Formats a value for the y axis and the tooltip. |
| `height` | number (pixels) | `240` | Plot height; the width follows the container. |

## Deep Linking

Not applicable: the component has no route or URL of its own and reads no URL
state.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a (literal) | "—" | Tooltip value for a missing or non-numeric value |

Series labels, x labels, and number formatting are supplied by the caller (the
`label`, `x`, and `format` inputs); the component adds no other visible text.

## Accessibility Options

- **Reduce Motion**: Satisfied — the component draws no animation (see
  no-animation).
- **Increase Contrast**: Not determinable from source: the colours are theme
  tokens whose resolved values the component does not define.
- **Differentiate Without Color**: Satisfied for identity — the legend names
  each series once there are two or more series, and the tooltip names every
  series by label (see legend-from-two-series). The lines themselves differ
  only by colour; a single series needs no differentiation.

## Feature Flags

Not applicable: the component contains no feature-flag or config-gating logic.

## Analytics

Not applicable: the component contains no analytics or telemetry calls.

## Privacy

- **Data collected**: None; the component only draws the points it is given.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the component contains no logging calls.

## Platform Notes

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

## Reference Implementations

| Platform | Path |
|----------|------|
| web | `packages/web/packages/adh-ui/src/components/time-series-chart.tsx` |

## Design Decisions

- **Decision**: One y scale only; a second measure of different scale needs a
  second chart.
  **Rationale**: Per source comment on the component in `time-series-chart.tsx`,
  the chart is for "a handful of series on ONE y scale (two measures of
  different scale belong in two charts, not a second axis)".
  **Approved**: pending
- **Decision**: At most four series, refused with a range error rather than
  truncated or given a generated colour.
  **Rationale**: Per source comment, "a fifth would need a generated hue, which
  is exactly the colour a reader can no longer tell apart — fold the tail into
  'Other' instead."
  **Approved**: pending
- **Decision**: A series keeps its colour slot by its position in the series
  list, never by its rank in the data.
  **Rationale**: Per the source comment on the series palette, assignment is
  fixed so a series keeps its colour as the data changes; the palette is the
  toolkit's own tagging hues, ordered so adjacent series stay apart for
  colour-blind readers.
  **Approved**: pending
- **Decision**: A null value is a gap in the line, never a zero.
  **Rationale**: Per the source comment on the point type, null means "no
  value", drawn as a break; `connectNulls` is off so a missing reading is not
  mistaken for a measured zero.
  **Approved**: pending
- **Decision**: A legend appears only from two series.
  **Rationale**: Per the source comment on the component, the legend exists so
  identity is never colour alone; a single series is named by the surrounding
  page, so the legend would repeat it.
  **Approved**: pending
- **Decision**: No entrance animation and no per-point dots.
  **Rationale**: The source disables animation and dots on every line, drawing
  a thin line with a marker only on the hovered point; the reason is not stated
  in source, so this records current behavior.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`screen-reader-support` is `partial`: the component adds no accessible name,
text alternative, or table alternative for the plot; only the chart library's
default accessibility layer (focusable region, arrow-key tooltip navigation)
exposes the data beyond the visual chart and hover tooltip. `contrast-ratio` is `partial`: all
colours are theme tokens whose resolved values cannot be determined from the
component. `string-externalization` is `partial`: the only fixed literal is the
tooltip's em dash, and every other string comes from the caller.
`data-minimization` passes: the component only draws what it is given and keeps
nothing. `separation-of-concerns` passes: `time-series-chart.tsx` only
presents points and series supplied by the caller, holding no data fetching,
aggregation, or state. `unit-test-coverage` is `partial`: `timeSeriesChart.test.tsx`
covers one line per series with a legend naming each, colouring by position,
no legend for a single series, formatting y-axis ticks, and refusing a fifth
series; the null gap, the tooltip placeholder, and the default height are not
yet asserted by a test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-10-04 | Mike Fullerton | Initial spec extracted from `time-series-chart.tsx`; accessibility and compliance statuses reflect the chart library's default keyboard layer. |
