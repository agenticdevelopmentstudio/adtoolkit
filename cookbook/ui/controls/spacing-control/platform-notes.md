
- **SwiftUI**: Model `Spacing` as an `@Binding` (or an `ObservableObject`)
  and draw the diagram with a `Canvas`/layered `Rectangle` shapes inside a
  fixed `.frame(width: 420, height: 250)`, applying the same `minimumSize`
  floor via `.frame(minWidth:minHeight:)` to mirror
  clips-below-minimum-size. Represent each arrow as a borderless `Button`
  with an SF Symbol `Image` (`"arrow.up"`, etc.) tinted `.accentColor`;
  SwiftUI's `Button` has no built-in continuous/periodic action, so
  mirroring repeats-held-arrow needs a `DispatchSourceTimer` (or a
  `Timer`) started on `.onLongPressGesture(minimumDuration: 0,
  pressing:)`'s press phase, at the same `0.45`s delay / `0.06`s interval.
  Bind each number to a `TextField` with a numeric `Formatter`, committing
  on `.onSubmit` to mirror commits-field-on-editing-end, and drive each
  handle with a `DragGesture(minimumDistance: 0)` measuring `.translation`
  from the gesture's start, applying the same 1:1 (edge) / 2:1 (gutter)
  gains.
- **Compose**: Draw the diagram with `Canvas`, sized
  `Modifier.size(420.dp, 250.dp)` with a `Modifier.sizeIn(minWidth =,
  minHeight =)` floor mirroring clips-below-minimum-size. Use `IconButton`s
  with `Icons.Filled.ArrowUpward`/etc. tinted via `MaterialTheme
  .colorScheme.primary` (the accent-tint analog), driving repeats-held-arrow
  with `Modifier.pointerInput` detecting `awaitFirstDown()` followed by a
  coroutine `while (isPressed) { delay(...); adjust(); }` loop at the same
  `450`ms/`60`ms cadence. Use `BasicTextField` with numeric
  `KeyboardOptions`, committing on `ImeAction.Done` or focus loss to
  mirror commits-field-on-editing-end, and `Modifier.draggable` (per
  handle, `Orientation.Horizontal`/`Vertical`) recording the value at drag
  start and accumulating each `onDelta` into a running total displacement —
  never applying a delta straight to the value — then computing
  `value = startValue + gain × totalDisplacement` on every callback, to
  mirror "measured from the value at drag start, not accumulated step by
  step".
- **React/Web**: Render the diagram as absolutely-positioned elements (or
  inline SVG) inside a fixed `420×250px` container with a `min-width`/
  `min-height` floor mirroring clips-below-minimum-size. Represent each
  arrow as a `<button>` with an SVG chevron tinted via `currentColor`/an
  accent CSS variable, driving repeats-held-arrow with `setInterval`
  (`450`ms initial delay, then a `60`ms interval, cleared on
  `pointerup`/`pointerleave`). Use an `<input>` that commits on `blur`/
  `Enter` (mirroring commits-field-on-editing-end) rather than on every
  `input` event, and a `pointerdown`-installed/`pointerup`-removed
  `pointermove` listener per handle that records the pointer's client
  position and the value at `pointerdown`, then on each `pointermove`
  computes the total displacement from that start position — not
  accumulated `movementX`/`movementY` deltas — and applies the same
  1:1/2:1 gains to it, to mirror "measured from the value at drag start,
  not accumulated step by step".
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/UI/Controls/Spacing/SpacingControl.swift`,
  with two companions this recipe also draws from:
  `Spacing.swift` (the spacing value type and the edge/gutter/arrow/axis
  enums it edits) and `SpacingControlLayout.swift` (the pure,
  view-independent geometry — chrome metrics, pane/gutter rects,
  arrow/field anchor points). macOS-only (`import AppKit`); there is no
  UIKit code path in source, and no touch-input handling to port. A
  UIKit/iOS port would need to redesign the hold-to-repeat arrows and the
  drag handles for touch (`UILongPressGestureRecognizer`/
  `UIPanGestureRecognizer`), since AppKit's `NSEvent`-loop-based tracking
  (`SpacingHandle.track(from:)`, `claimsPress`) has no UIKit equivalent.

  The control is an `NSView`; it does not support construction via
  `init(coder:)` — that initializer traps with a fatal error and returns no
  instance — since the control is always built in code, never loaded from
  a nib or storyboard. `apply(_:)`'s equality guard is what backs
  skips-redundant-onchange. Field commit fires from
  `controlTextDidEndEditing`; recovering unparseable text is
  `control(_:didFailToFormatString:errorDescription:)` returning `true` and
  rewriting the field editor's text. Held-arrow repeat is driven by
  `ArrowButton.isPressed` and `setPeriodicDelay`; the frozen-pair guard is
  `seat(_:holding:)`'s `holdsPressedArrow` check. Drag handles are tracked
  by `SpacingHandle.track(from:)`/`claimsPress`, bounded by `grace`
  (`0.12`s) and `patience` (`0.3`s), with jitter filtered below `slop`
  (`3pt`). Tab order is intercepted explicitly inside
  `control(_:textView:doCommandBy:)` (`insertTab`/`insertBacktab`) rather
  than relying on AppKit's inferred key-view loop, and arrow-key adjustment
  is `moveUp`/`moveDown`. Mid-edit preservation and the forced redisplay
  after commit both go through `show(_:in:force:)`; general state sync is
  `sync()`, and redraw/relayout triggers are `needsDisplay`/`needsLayout`
  (forced synchronously during a drag via
  `layoutSubtreeIfNeeded()`/`displayIfNeeded()` so the diagram tracks the
  pointer within the same run-loop turn, rather than waiting for AppKit's
  own next display cycle). The disabled state is never touched
  (`isEnabled` is never set on any subview).

  Accessibility grouping uses `setAccessibilityElement(true)` and
  `setAccessibilityRole(.group)`; every field, stepper, arrow button, reset
  button, and drag handle also carries a `setAccessibilityIdentifier` value
  via the shared `accessibilityID(_:)` helper. The number fields
  (`edgeFields`/`gutterFields`) and their steppers carry no
  `setAccessibilityLabel`/`setAccessibilityTitleUIElement`; the arrow
  buttons instead get their VoiceOver label from an
  `NSImage(systemSymbolName:accessibilityDescription:)`'s
  `accessibilityDescription`. This is a pointer/trackpad-driven
  `NSView`/`NSControl` composition with no touch input path, which is why
  the 44×44pt touch-target minimum does not apply.

  Natural size is `intrinsicContentSize`/`controlSize` (`420×250pt`);
  minimum-size floors are `fieldGroupSize` (`55×21pt`) and
  `minimumDiagramSize` (tied to `maximumDisplayedInset`); the diagram's
  drawn rectangle is `diagramRect`, measured from `bounds` on every layout
  pass. Outer/pane rectangles are drawn with `NSBezierPath(rect:)` (no
  `cornerRadius` anywhere); hairline strokes are inset via
  `insetBy(dx: 0.5, dy: 0.5)` for crisp non-Retina-scaled edges; chrome
  metrics (`diagramInset`, an arrow's `attachment` offset, a divider
  pair's `pairOffset`) live in `SpacingControlLayout.swift`'s
  `Metrics.chrome`. Theme repaint is driven by `observeTheme`; drawn colors
  and fonts resolve through `SemanticPalette` —
  `palette.nsColor(.primaryText)`, `palette.nsColor(.accent)` (via
  `contentTintColor`), `palette.nsColor(.border)`,
  `palette.projectPaneBackdrop`, `palette.projectPaneOutline`,
  `palette.nsColor(.windowBackground)`, `palette.font(.code)`,
  `palette.font(.body)`. The open contrast question
  (minimum-contrast-ratio) concerns `SemanticPalette.derive(_:theme:)`
  (`packages/apple/AgenticDeveloperToolkit/Sources/Theme/SemanticPalette.swift`)
  and would need a `SemanticPalette`-derived Increase-Contrast variant
  sourced from `NSWorkspace.accessibilityDisplayShouldIncreaseContrast`.

  Settings binding: `SpacingSettingsBinding` and the
  `SpacingControl.boundToSettings(style:edges:gutters:range:)` factory
  (`SpacingSettingsBinding.swift`, a separate file, out of this recipe's
  scope) tie a control to `UserSetting<Int>` values; its `precondition`
  traps if the `edges`/`gutters` list for the requested style is empty.
  `PaneSpacing`'s `edgeSettings`/`gutterSettings` and
  `ComposableTabsSettingsViewController` are two concrete callers, cited
  here for traceability. The control retains only its own subviews, its
  `value`, and (when bound) its `retainedBinding`.

  `style`/`range`/`value` are non-optional typed initializer parameters
  (Swift's type system rules out `nil` for any of them); `value` defaults
  to `Spacing()` (all zero). Every write path clamps through
  `Spacing.adjusting`/`Spacing.setting` (`Int.clamped(to:)`); assigning
  `value` directly only runs its `didSet`'s equality check and redraw, and
  the stepper's own `minValue`/`maxValue` (set from `range` at
  construction) clamp it independently. `SpacingControl` is
  `@MainActor`-isolated, so Swift's concurrency checker serializes all
  access to the main actor, and the drag-tracking loop
  (`SpacingHandle.track`) runs synchronously to completion on that same
  actor before returning. Every operation (formatting, clamping, layout,
  drawing) is synchronous and non-throwing — no `try`, `Result`, or
  error-producing API appears anywhere in this file. No
  `NSAnimationContext`/`animator()` call appears in source, so redraw and
  layout (`needsDisplay`, `needsLayout`) are instantaneous, non-animated
  property assignments. Every user-facing string (see Localization) is an
  AppKit `String` literal assigned to `toolTip`, `title`, or an `NSImage`'s
  `accessibilityDescription` — never a `LocalizedStringKey`,
  `NSLocalizedString`, or a String Catalog lookup. No logging call
  (`print`, `os_log`) appears anywhere in source, and calling
  `SpacingControl(coder:)` traps with a fatal error and returns no
  instance.
- **WinUI 3**: Build the diagram as a
  `Canvas` (or a `Grid` of `Border` elements for the container/panes)
  inside a `UserControl` with `Width="420" Height="250"` and a `MinWidth`/
  `MinHeight` floor mirroring clips-below-minimum-size. Draw the outer
  frame and panes as `Border`/`Rectangle` elements whose `Background`/
  `BorderBrush` are bound to `ThemeResource` brushes mirroring
  `SemanticPalette`'s `.border`/`.windowBackground`/project-pane tokens —
  never a literal `Color`, matching this file's theme-token-only-colors
  discipline. Represent each arrow as a chrome-less `Button`
  (`Background="Transparent" BorderThickness="0"`) hosting a `FontIcon`/
  `PathIcon` glyph tinted with an accent `ThemeResource`; WinUI's
  `RepeatButton` (with its own `Delay`/`Interval` properties) is a closer
  built-in match for repeats-held-arrow than a plain `Button` plus a
  hand-rolled `DispatcherTimer`, and should replace it outright, configured
  to the same `450`ms delay / `60`ms interval. Bind each number to a
  `NumberBox` (`SpinButtonPlacementMode="Compact"` supplies the stepper for
  free) with `Minimum`/`Maximum` bound to `range`, committing via
  `ValueChanged` only after `LostFocus`/Enter to mirror
  commits-field-on-editing-end. `NumberBox`'s built-in
  `ValidationMode="InvalidInputOverwritten"` only reverts to the previous
  value on any unparseable text, which is not the full analog of
  recovers-unparseable-field-text: that requirement still wants the
  *clamped* typed number when one can be parsed — even from an out-of-range
  or partially-numeric string — and falls back to the held number only when
  nothing parses at all. Closing that gap needs a custom `TextSubmitted`
  handler that parses the typed text itself, clamps a successful parse to
  `range`, and reverts to the held number only when parsing fails outright.
  Implement the drag handles with `ManipulationMode="TranslateX,TranslateY"`
  and a `ManipulationDelta` handler computing the same 1:1 (edge) / 2:1
  (gutter) gains, and route `KeyDown` (`VirtualKey.Up`/`Down`) plus
  explicit `TabIndex` ordering (top/leading/trailing/bottom, or gutter
  order) across the `NumberBox`es to mirror tab-order-is-picture-order and
  arrow-keys-adjust-focused-field, since WinUI's default tab-index
  navigation cannot infer the picture's reading order from `Canvas`-based
  placement any more than AppKit's inferred key-view loop could from
  frame-based placement.
- **UI-thread confinement**: `confines-to-ui-thread` — the type is declared `@MainActor` and is an `NSView` subclass, so construction or mutation from off the main actor fails to compile; the drag-tracking loop also runs on the main actor.

