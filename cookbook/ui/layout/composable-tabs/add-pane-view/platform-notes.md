
- **SwiftUI**: Model the sheet as a small form presented via
  `.sheet(isPresented:)`, with a `Picker("Add:", selection: $selectedChoice)`
  populated from `choices` and a `Picker("Where:", selection:
  $selectedDirection)` populated from the four `Direction` cases,
  defaulting `selectedDirection` to `.right`. Give an "Add" option a
  `Label(choice.displayName, systemImage: choice.symbolName)` when a symbol
  exists, mirroring the source's per-item image. A footer `Button("Cancel")`
  with `.keyboardShortcut(.cancelAction)` and `Button("OK")` with
  `.keyboardShortcut(.defaultAction)` reproduce the Escape/Return bindings,
  and `.disabled(choices.isEmpty)` computed once at sheet-open time
  reproduces the fixed-at-load OK enablement.
- **Compose**: Use two dropdown-menu composables inside an `AlertDialog`
  (or a `Dialog` with custom content) — one bound to a `selectedChoice`
  state seeded to the first entry, or to no selection when `choices` is
  empty, one to a `selectedDirection` state seeded to the "right"
  direction. Render each Add-menu item with an
  optional leading icon when a symbol equivalent exists, mirroring the
  source's per-item image. Wire the dialog's confirm/dismiss actions
  through its own confirm/dismiss slots, disabling the confirm action once,
  at open time, when `choices` is empty, mirroring the fixed-at-load
  `okButton.isEnabled`.
- **React/Web**: A small modal built on a dialog primitive, containing two
  native selection controls — one populated from `choices` (each option
  carrying the choice's `displayName`, with an optional leading icon
  rendered alongside if icons are needed), one populated from the four
  direction labels defaulting to "Right" — plus "Cancel" and "OK" buttons.
  Bind Escape to Cancel and Enter/form submit to OK, mirroring the AppKit
  key equivalents, and set the OK button's disabled state once, at open
  time, from `choices.length === 0`, mirroring the source's fixed-at-load
  enablement rather than a reactive binding.
- **AppKit / UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsAddPaneViewController.swift`
  as a `@MainActor`, `final` `NSViewController` with no nib/XIB —
  `loadView()` builds an `NSGridView` of two `NSPopUpButton`s and their
  `ThemedLabel` captions, plus an `NSStackView` of Cancel/OK `NSButton`s,
  laid out with Auto Layout against a `ThemedBackgroundView` root. Arrange
  mode presents it as a sheet from its Add button. It also does not support
  construction via a coder-based initializer — Cocoa's `NSCoder`-driven
  `init(coder:)` — which this type overrides to trigger a fatal error
  immediately, since no code path in this app constructs this sheet from an
  archived storyboard/xib. There is no UIKit code path in source; a UIKit
  port would replace the two `NSPopUpButton`s with `UIButton`s presenting
  menus (or two rows of a grouped table/picker view), replace the grid with
  a stack view of horizontal rows, and present the whole thing as a small
  view controller in a form-sheet presentation, since UIKit has no direct
  analog of `NSGridView`/`NSPopUpButton`.
- **WinUI 3**: Build the sheet as a
  `ContentDialog` with `PrimaryButtonText="OK"` and
  `CloseButtonText="Cancel"` — `ContentDialog` already binds its primary
  button to Enter and its close button to Escape, the direct analogs of the
  source's Return/Escape key equivalents — and set `IsPrimaryButtonEnabled`
  once, at open time, from `Choices.Count > 0`, mirroring the fixed-at-load
  `okButton.isEnabled` rather than a live binding. Lay out two rows of
  `TextBlock` + `ComboBox` in a `Grid` with two `RowDefinitions` and two
  `ColumnDefinitions` (label column `HorizontalAlignment="Right"`,
  matching the source grid's trailing label placement) — an "Add:" row
  bound to a `ComboBox` populated from the choices collection (each item a
  horizontal panel of an optional icon glyph plus a text run for the
  display name, mirroring the source's per-item SF Symbol image) and a
  "Where:" row bound to a `ComboBox` of the four direction labels, with
  `SelectedIndex` initialized to the index of "Right". Handle the
  `ContentDialog`'s primary-button-click event to read both `ComboBox`
  selections and raise the add-pane event only after `ShowAsync()` has
  returned and the dialog has closed, mirroring the source's
  dismiss-before-invoke ordering in the confirm action.
- **UI-thread confinement**: `confines-to-ui-thread` — the view controller is declared `@MainActor`, so use from off the main actor fails to compile.

