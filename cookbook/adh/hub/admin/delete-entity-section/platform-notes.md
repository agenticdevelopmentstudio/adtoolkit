
- **SwiftUI**: Build the collapsed Danger Zone from a `DisclosureGroup(isExpanded:)`
  bound to a `@State` flag equivalent to `disclosed`; recolor only the group's
  label `Text` with `.foregroundStyle(.red)` while `isExpanded` is `true` (the
  `Image(systemName: "exclamationmark.triangle")` warning glyph keeps a fixed gold
  `Color` in both states — see accent-red-only-when-disclosed and
  keep-warning-glyph-gold). Model the two dialog phases as an enum driving
  `.alert(item:)`/`.sheet(item:)` rather than one dialog whose body swaps: the warn
  phase is a plain `.alert` with Cancel/Yes actions, the confirm phase is a
  `.sheet` containing a `TextField` bound to `@State var typed`, with the
  destructive `Button`'s `.disabled(typed != confirmValue || confirmValue.isEmpty)`
  computed as the exact, untrimmed comparison the source uses. Set
  `.interactiveDismissDisabled(busy)` on the confirm sheet to reproduce
  lock-dialog-while-busy, and swap `Image(systemName: "trash")` for
  `"archivebox"` when `actionVerb.reversible` is `true`.
- **Compose**: Use a `Card` with a header `Row` that toggles a
  `rememberSaveable { mutableStateOf(false) }` expanded flag, wrapping the body in
  `AnimatedVisibility`; recolor only the header `Text` with
  `MaterialTheme.colorScheme.error` while expanded, keeping the
  `Icons.Filled.Warning` `Icon` tinted with a fixed gold color in both states.
  Drive the two-phase confirm with two `AlertDialog`s selected by a `phase`
  enum held in `remember` (or a `ViewModel`); the second `AlertDialog`'s
  `confirmButton` sets `enabled = typed.isNotEmpty() && typed == confirmValue`,
  matching the source's exact, untrimmed comparison. While `busy` is `true`, pass
  `onDismissRequest = {}` and omit the dismiss button on the second dialog to
  block dismissal, and swap `Icons.Filled.Delete` for `Icons.Filled.Archive` when
  `actionVerb.reversible` is `true`.
- **React/Web**: `packages/web/packages/adh-ui/src/blocks/delete-entity-section.tsx`
  (`"use client"`), exported via `@agentic-toolkit/adh-ui/blocks/delete-entity-section`.
  Composes `Disclosure`, `Button`, `Dialog` (+ `DialogHeader`/`Title`/`Description`/
  `Footer`), `Input`, and `Label`, with the `Trash2`/`TriangleAlert`/`Archive`
  glyphs from `lucide-react`. Props: `entityNoun`, `confirmValue`, `childEntities`,
  `onConfirm: () => Promise<void>`, optional `description`, and optional
  `actionVerb: { imperative, gerund, reversible? }` (default `{ imperative:
  "Delete", gerund: "Deleting", reversible: false }`, which reproduces today's
  wording byte-for-byte). Every color is drawn from an `apt-*` theme token — no raw
  hex value and no `!important` override appear anywhere in the styling. Demo lives
  in the `ui-showcase` Topic
  `delete-entity-section` (regenerate `sources.generated.ts` via
  `gen-sources.py` after source changes); verify responsively via Playwright at
  375 / 768 / 1440. Shared across every focused-topic-detail settings route
  (`adtoolkit://cookbook/ui/navigation/focused-topic-detail`), usually as the final
  group in a settings pane below the `FieldGroup`s.
- **AppKit/UIKit**: On macOS, build the disclosure from an `NSButton` with
  `bezelStyle = .disclosure` (there is no `NSDisclosureButton` class) toggling a
  subview's `isHidden`, recoloring only the title `NSTextField` with
  `NSColor.systemRed` while expanded. Present the acknowledge phase as an
  `NSAlert` (Cancel/Yes), but present the type-to-confirm phase as its own sheet
  window (`NSWindow` shown via `beginSheet(_:completionHandler:)`) rather than a
  second chained `NSAlert` — `NSAlert.runModal` cannot represent an async busy
  state (a disabled CTA with a "Deleting…" label) or a suppressed close control,
  which a sheet's own view controller can. The sheet carries an `NSTextField`
  whose delegate (`controlTextDidChange`) enables the confirm `NSButton` only on
  an exact `String` equality against `confirmValue`, and disables both that
  button and its Cancel button while busy. The two dialogs are never open at
  once: the acknowledge `NSAlert` must finish (and be dismissed) before the
  confirm sheet is presented. On iOS, use a collapsible `UIStackView` section and
  a chained `UIAlertController` (`.alert`) for the acknowledge phase, then a
  second `UIAlertController` built with `addTextField` and a
  `.textDidChangeNotification` observer that gates the confirm `UIAlertAction`'s
  `isEnabled` the same way, disabling both actions while busy. Block dismissal
  while busy by setting `isModalInPresentation = true` (iOS) or omitting the
  sheet's close control (macOS) until the async delete settles, and swap the
  trash `UIImage`/`NSImage` (`systemName: "trash"`) for `"archivebox"` when
  `actionVerb.reversible` is `true`.
- **WinUI 3**: Use an `Expander` (`IsExpanded="{x:Bind Disclosed, Mode=TwoWay}"`)
  for the Danger Zone, collapsed by default. Bind the `Header` `TextBlock`'s
  `Foreground` to a `SolidColorBrush` resource selected by a
  `VisualStateManager` state (`Disclosed` / `Collapsed`) so the red accent brush
  applies only while expanded — never a converter on the warning icon, whose
  `FontIcon.Foreground` stays a fixed gold brush in both states (see
  accent-red-only-when-disclosed and keep-warning-glyph-gold). Trigger a
  `ContentDialog` for the acknowledge phase (`PrimaryButtonText="Yes"`,
  `CloseButtonText="Cancel"`), then a second `ContentDialog` with a `TextBox`
  whose `TextChanged` handler sets `IsPrimaryButtonEnabled` from
  `string.Equals(textBox.Text, confirmValue, StringComparison.Ordinal) &&
  confirmValue.Length > 0` (reproducing require-exact-identifier and
  reject-empty-confirm-value). The two `ContentDialog`s are never shown
  concurrently: the acknowledge dialog's `Hide()` completes before the confirm
  dialog is shown. In the `PrimaryButtonClick` handler, call
  `args.GetDeferral()` before awaiting the delete, set
  `IsPrimaryButtonEnabled = false` and swap the button content for a
  `ProgressRing` plus "Deleting…" text while the call is pending — a
  `ContentDialog` otherwise stays light-dismissible during an async
  `PrimaryButtonClick`, so the deferral is what reproduces
  lock-dialog-while-busy. On success, call `deferral.Complete()` to let the
  dialog close. On failure, bind a `TextBlock` to the caught message and make it
  visible, set `args.Cancel = true` to keep the dialog open, then call
  `deferral.Complete()` — completing the deferral either way is required, since
  leaving it pending wedges the dialog; `args.Cancel = true` is what actually
  keeps it open for retry (surface-error-inline). Swap
  the `FontIcon` glyph from the Segoe Fluent Icons trash glyph (`\uE74D`) to the
  archive glyph (`\uE7B8`) when `actionVerb.reversible` is `true`.

