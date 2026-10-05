
- **SwiftUI**: The source is pure AppKit (`NSViewController`), not SwiftUI.
  A SwiftUI port would replace `loadView()`'s manual `NSStackView`/
  `NSLayoutConstraint` footer with a `VStack` (tree, `Divider()`, footer
  `HStack`), replace the two `NSButton`s with `Button` views driving the same
  `addDirectory()`/`removeSelectedDirectory()` logic, and replace
  `FileBrowserSelection`/`FileBrowserDirectories` (already `Combine`
  `ObservableObject`s) with `@ObservedObject`/`@StateObject` wrappers — they
  need no redesign, only new call sites.
- **Compose**: Start from a `Column` with the tree composable, an
  `HorizontalDivider`, and a `Row` footer holding two `IconButton`s (add/
  remove) bound to the same enablement rule
  (`remove-button-enablement`). `FileBrowserDirectories`/
  `FileBrowserSelection` become a `ViewModel` exposing `StateFlow`s; the
  watch-on-appear/stop-on-disappear lifecycle maps to `DisposableEffect`
  keyed on composition entering/leaving.
- **React/Web**: The tree becomes a virtualized list/tree component; the
  footer becomes a flex row with two icon buttons calling the same add/
  remove handlers, disabling the remove button by the same rule. FSEvents
  watching has no direct web equivalent — `start-watching-on-appear`/
  `stop-watching-on-disappear` would map to subscribing/unsubscribing a
  polling or server-push channel when the component mounts/unmounts
  (`useEffect` cleanup).
- **AppKit / UIKit**: This is the source platform (AppKit/macOS). The
  container is an `NSViewController`; the divider is an `NSBox` with
  `boxType: .separator`; the footer sits in an `NSStackView` with 2pt
  horizontal spacing between two plain `NSButton`s (`bezelStyle:
  .accessoryBar`, not the framework's rounded `ThemedButton`), each with an
  empty title and rendered as an SF Symbol image only (`plus`, `minus`) with
  `accessibilityDescription: nil`, and no explicit accessibility label/title
  beyond `NSView.accessibilityID(_:)`. The root/footer fills use
  `ThemedBackgroundView` for the `.windowBackground`/`.surface` roles.
  Directory selection uses `NSOpenPanel` (`canChooseDirectories: true`,
  `canChooseFiles: false`, `allowsMultipleSelection: true`); refusal
  feedback is `RefusalFeedback.announce()`, by default `NSSound.beep()`.
  Constructing the component from decoded/serialized state (`init(coder:)`)
  is marked `@available(*, unavailable)` and calls `fatalError` if somehow
  invoked at runtime — AppKit requires this initializer to exist on an
  `NSViewController` subclass even though this component is never built from
  a storyboard/nib. The directories/selection/restoration state are
  `@MainActor`-isolated Combine `ObservableObject`s; changes to the
  additional roots are received on the main queue (`receive(on:
  DispatchQueue.main)`) before triggering a manager rebuild. AppKit does not
  localize `toolTip`/`NSOpenPanel.prompt`/`NSOpenPanel.message` the way
  SwiftUI's `Text` localizes a literal, so the five user-facing strings are
  genuinely unlocalized literals with no key scheme. On iOS,
  `NSViewController` becomes `UIViewController`, `NSOpenPanel` becomes a
  `UIDocumentPickerViewController` configured for directories, `NSButton`
  becomes `UIButton`, and `NSStackView`/`NSBox` become `UIStackView`/a
  hairline `UIView`; the FSEvents-backed watch/stop lifecycle would need to
  move to `viewWillAppear(_:)`/`viewDidDisappear(_:)` on `UIViewController`,
  matching this file's `viewWillAppear()`/`viewDidDisappear()` exactly.
  Internally, the source tracks these per-root managers in a private
  `managersByRoot: [URL: FileTreeManager]` dictionary and gates the
  once-only load and the watch/stop toggle on private `hasLoaded`/
  `isWatching` booleans — implementation detail a conforming reimplementation
  is free to represent differently; the requirements and test vectors above
  describe only the observable load/watch behavior, never these names.
- **WinUI 3**: Model the tree as a `TreeView` (or `NavigationView` with a
  `TreeView` in its pane) hosted in a `Grid` with two `RowDefinition`s: the
  tree's row set to `*`, and a fixed-height footer row below a
  `<MenuFlyoutSeparator>`-style `Border` acting as the divider. The footer is
  a horizontal `StackPanel` with two `Button`s carrying `FontIcon`s — Segoe
  Fluent glyphs written as escaped code points rather than raw glyph
  characters, for example `\uE710` for add/plus and `\uE738` for
  remove/minus — in place of the SF Symbols; each button's
  `AutomationProperties.Name` should carry the same text the source puts in
  `toolTip`, since WinUI has no tooltip-as-accessible-name fallback to rely
  on the way this recipe's Accessibility section flags as unresolved for
  AppKit. Directory selection uses `Windows.Storage.Pickers.FolderPicker` in
  place of `NSOpenPanel`; unlike `NSOpenPanel`'s `allowsMultipleSelection`,
  `FolderPicker` returns exactly one folder per call, so multi-directory
  selection must be emulated with a loop of repeated
  `PickSingleFolderAsync()` calls, each shown to the user in turn, and the
  UI should say so explicitly (e.g. "Add another?") rather than silently
  serializing multiple picks behind what looks like one dialog. The remove button's enabled/disabled pair
  maps to a `VisualStateManager` state pair (`Enabled`/`Disabled`) toggled
  from the same `selection.selectedRoot` rule, with the `IsEnabled` binding
  driving `Button.IsEnabled` and a `ToolTipService.ToolTip` binding driving
  the dynamic message. `FileTreeManager`'s FSEvents watch has no 1:1 WinUI
  primitive; use a `Windows.Storage.Search.StorageFolderQueryResult` with a
  `ContentsChanged` handler started/stopped from the page's
  `Loaded`/`Unloaded` events, mirroring `start-watching-on-appear`/
  `stop-watching-on-disappear`.

