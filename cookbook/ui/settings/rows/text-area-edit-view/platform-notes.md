
- **SwiftUI**: Pair a `Text(viewModel.title)` above a `TextEditor(text:
  $value)`, sized with `.frame(minHeight: lineHeight * CGFloat(visibleLines))`
  and wrapped in a bordered container to stand in for the scroll view's
  bezel chrome. Do not commit on every `TextEditor` keystroke; instead track
  focus with `@FocusState` and commit (write through an equality guard,
  mirroring redundant-commit-guard) when focus leaves the editor, and again
  from a `.onDisappear`/scene-teardown hook, mirroring
  window-detachment-commit and teardown-notification-observers. Disable
  autocorrection/smart substitutions with `.autocorrectionDisabled()` as the
  SwiftUI analog of automatic-substitution-suppression, and add an explicit
  `.accessibilityLabel(viewModel.title)`, carrying over accessibility-label
  rather than treating it as optional.
- **Compose**: Use a `Column` with `Text(title)` above an `OutlinedTextField`
  (or `BasicTextField` inside a `Box` with `verticalScroll`) configured
  `singleLine = false`, height-capped to `visibleLines` rows. Commit inside
  `Modifier.onFocusChanged { if (!it.isFocused) commit() }` — Compose's
  analog of end-editing-commit — with an equality check before writing,
  mirroring redundant-commit-guard, and again from `DisposableEffect`'s
  `onDispose`, mirroring window-detachment-commit. Give it
  `Modifier.semantics { contentDescription = title }`, mirroring
  accessibility-label, and drive font/color from
  `MaterialTheme.typography`/`colorScheme` tokens equivalent to
  `.body`/`.code`, `primaryText`, and `controlBackground`.
- **React/Web**: A `<label>` above a `<textarea rows={visibleLines}>` whose
  `id` the label's `htmlFor` references — carrying over accessibility-label
  rather than introducing a gap. Commit on the textarea's `onBlur` (not
  `onChange`, which fires per keystroke) and again from a component-unmount
  effect / `beforeunload` handler, mirroring end-editing-commit and
  teardown-notification-observers, each guarded by an equality check
  mirroring redundant-commit-guard. Set `spellCheck={false}` and avoid any
  smart-quote/dash text-processing library as the web analog of
  automatic-substitution-suppression, and style font/color from theme
  tokens equivalent to `.body`/`.code`, `primaryText`, and
  `controlBackground`.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/TextAreaEditView.swift`
  — a macOS-only (`import AppKit`), `@MainActor`, non-`final` `NSView`
  subclass inside the `ComposableSettings` namespace, conforming to
  `SettingsViewProtocol` and `NSTextViewDelegate` directly (not by
  subclassing `TextEditView`, though it reuses that class's static
  `createLabel(title:)` helper). Being non-`final`, it may itself be
  subclassed. It is constructed only via `init(viewModel:visibleLines:
  monospaced:)`; the frame-only `init(frame:)` and the fatal-erroring
  `init?(coder:)` are the only other initializers, so construction is
  restricted to the one path that supplies a view model. The `@MainActor`
  declaration confines construction and mutation to the main actor under
  Swift's concurrency checking. `NSTextViewDelegate` conformance is how the
  editor's own end-of-editing callback reaches the component directly
  (`textView.delegate = self`, `textDidEndEditing` as the commit path)
  rather than through a separate delegate object. There is no UIKit code
  path in source. A UIKit port would replace `NSTextView`/`NSScrollView`
  with a `UITextView` (which is natively scrolling, so no separate scroll
  view is needed), implement `UITextViewDelegate.textViewDidEndEditing(_:)`
  as the commit path, and disable `autocorrectionType`/`smartQuotesType`/
  `smartDashesType`/`smartInsertDeleteType` as the substitution-disabling
  analog. Concretely, the AppKit source satisfies plain-text-mode via
  `textView.isRichText = false`; undo-support via `textView.allowsUndo =
  true`; automatic-substitution-suppression via
  `isAutomaticQuoteSubstitutionEnabled`,
  `isAutomaticDashSubstitutionEnabled`, and
  `isAutomaticTextReplacementEnabled`, all `false`; vertical-growth via
  `isVerticallyResizable = true`, `isHorizontallyResizable = false`,
  `autoresizingMask = [.width]`, `minSize = .zero`, `maxSize =
  NSSize(width: .greatestFiniteMagnitude, height:
  .greatestFiniteMagnitude)`; text-wrapping via
  `textView.textContainer.widthTracksTextView = true` and `containerSize =
  NSSize(width: 0, height: .greatestFiniteMagnitude)`; text-container-inset
  via `textView.textContainerInset = NSSize(width: 4, height: 4)`;
  scrolling-container via an `NSScrollView` with `documentView = textView`,
  `hasVerticalScroller = true`, `borderType = .bezelBorder`;
  scroll-view-theme-background via the scroll view's `drawsBackground =
  true` and its themed `backgroundColor`; label-scroll-view-layout via an
  `NSStackView`; visible-height via the scroll view's height constraint
  constant `(textView.font!.boundingRectForFont.height *
  CGFloat(visibleLines)).rounded() + 8` (the trailing `+ 8` matching
  `textContainerInset`'s 4pt top and 4pt bottom insets, per Design
  Decisions) and a width constraint equal to the stack's width; and
  superview-width-claim via a `widthAnchor` constraint at priority
  `.required - 1` (999). The caret-position quirk in Edge Cases stems from
  computing `viewModel.value.count` (a grapheme-cluster count) and passing
  it as an `NSRange` location, which `NSTextView` interprets in UTF-16 code
  units.
- **WinUI 3** (the reason this recipe exists): Build the row as a vertical
  `StackPanel` (8px `Spacing`, the WinUI analog of the row's standard
  spacing) containing a `TextBlock` for the title and a `TextBox` with
  `AcceptsReturn="True"` and `TextWrapping="Wrap"` — WinUI's own scrolling,
  multi-line text control, so no separate `ScrollViewer` is required the way
  `NSTextView` requires `NSScrollView` (set
  `ScrollViewer.VerticalScrollBarVisibility="Auto"` on the `TextBox` if an
  explicit scrollbar affordance is wanted). Give the `TextBox` a fixed
  `Height` computed the same way as visible-height (line height ×
  `visibleLines`), plus the `TextBox`'s own default vertical `Padding` and
  `BorderThickness` (from the `TextBoxPadding` and
  `TextControlBorderThemeThickness` theme resources) rather than reusing
  AppKit's `+ 8` constant, which is specific to `NSTextView`'s 4pt top/bottom
  `textContainerInset` — so overflow scrolls internally rather than growing
  the row. Commit on the `TextBox.LostFocus` event — WinUI's analog of
  `textDidEndEditing` — and also from the `Window.Closed` event and
  `AppWindow.Closing` (a WinUI 3 desktop app receives neither of UWP's
  `Application.Current.Suspending`), plus a process-exit handler for the
  case neither fires, mirroring window-detachment-commit and
  teardown-notification-observers, each guarded by an equality check
  mirroring redundant-commit-guard. Bind `TextBox.Foreground` and
  `Background` to theme resource brushes equivalent to
  `primaryText`/`controlBackground`, and `SelectionHighlightColor`/
  `SelectionHighlightColorWhenNotFocused` to a brush equivalent to
  `selection`, mirroring editor-theme-colors. Set `AutomationProperties.Name`
  on the `TextBox` to the title — the WinUI analog of
  `setAccessibilityLabel`, and one this AppKit source already implements,
  so carry it over rather than treating it as a gap to fix. `TextBox` has no
  direct equivalent of AppKit's quote/dash auto-substitution toggles; the
  nearest analog, `TextBox.IsSpellCheckEnabled = false`, only covers
  spell-check underlining, not autocorrection — note this as a platform gap
  rather than claiming full parity with automatic-substitution-suppression.

