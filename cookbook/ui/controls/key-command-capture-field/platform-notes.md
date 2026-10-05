
- **SwiftUI**: There is no built-in SwiftUI equivalent for raw key-equivalent
  interception. Wrap this exact AppKit type in an `NSViewRepresentable`
  rather than reimplementing it, because `onKeyPress`/`.focusable()`
  (macOS 14+) observe key events but do not intercept primary-modifier
  chords ahead of the menu/window the way `performKeyEquivalent` does —
  the same problem a standard text field's field editor has. Expose
  `onCapture`/`onCancel`/`onCommit`/`onRecordingChanged` as `Binding`s or
  closures passed through the representable's coordinator.
- **Compose**: There is no window-level "key equivalent" concept in Compose;
  the closest analog is a focusable composable with
  `Modifier.onPreviewKeyEvent { ... }` on a `FocusRequester`-focused node,
  which sees key events before children (and, at the platform level, before
  most system shortcut handling) the way `performKeyEquivalent` runs before
  the menu/window. Mirror unmodified-tab-passthrough by returning `false`
  (unhandled) for a bare Tab/Shift-Tab `KeyEvent` and drive the
  recording boolean from `Modifier.onFocusChanged`, the Compose analog of
  gaining/losing focus.
- **React/Web**: A `<div>` (or a read-only `<input>`, to get a native focus
  ring for free) with `tabIndex={0}` and an `onKeyDown` handler reading
  `event.key`/`event.code` plus the modifier booleans. Call
  `event.preventDefault()` for every combination the field decides to
  capture, since a Ctrl/Cmd-chord can otherwise trigger the browser's or
  OS's own shortcuts — the DOM analog of intercepting a key equivalent
  before the menu claims it — but deliberately skip `preventDefault()` for
  a bare Tab/Shift-Tab so native focus order is preserved, mirroring
  unmodified-tab-passthrough. Add `role="button"` (or `role="group"` if the
  recorder is treated as a composite control) plus an explicit `aria-label` to
  supply the accessible label the source itself never assigns (see
  Accessibility above), and an `aria-live="polite"` region announcing
  recording start/stop and the captured-chord description to supply the
  state announcement the source itself never makes (see Announce state
  changes above) — `role="textbox"` would incorrectly tell assistive tech to
  expect editable text, which this control is not.
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/macOS/Features/KeyCommands/KeyCommandCaptureField.swift`.
  A macOS-only (`import AppKit`) `NSView` subclass, `@MainActor`, depending
  on the third-party `KeyboardShortcuts` package (github.com/sindresorhus/
  KeyboardShortcuts) for its `Shortcut` type and key constants, and on
  `AgenticToolkitCore`'s theming (`observeTheme`, `SemanticPalette`). The
  primary modifier on this platform is Command: the "primary modifier plus
  K"/"primary modifier plus Shift plus K"/"Option plus primary modifier
  plus P" test-vector inputs above correspond to ⌘K, ⌘⇧K, and ⌥⌘P
  respectively. `confines-to-ui-thread` is enforced by the class and its
  public API being declared `@MainActor`, so construction or mutation from
  off the main actor fails to compile — a static, compile-time check
  rather than a vector observed by running the program; a port on a
  platform without an equivalent compile-time enforcement should verify
  this as a build-verification note rather than a runtime test.
  `coder-initialization-rejection` is implemented as a fatal error on
  `init?(coder:)`, since this component provides no Interface
  Builder/`NSCoding` support. There is no UIKit code path in source and
  none is implied — iOS has no key-equivalent chain or hardware-shortcut
  recording concept comparable to this component's purpose. click-focus is
  implemented as a direct `window?.makeFirstResponder(self)` call from
  `mouseDown(with:)`; the pre-dispatch interception/deferral requirements
  are implemented by overriding `performKeyEquivalent(with:)` (deferring to
  `super.performKeyEquivalent(with:)` when idle), and the regular
  key-handling deferral is implemented by overriding `keyDown(with:)` to
  call `super.keyDown(with: event)`; `incidental-modifier-stripping`
  computes the modifier set from `event.modifierFlags` restricted to
  `.deviceIndependentFlagsMask` with `.function`, `.numericPad`, and
  `.capsLock` removed; `pointing-hand-cursor` is registered via
  `resetCursorRects()`; redundant-recording-notification-suppression is
  implemented as an early return in the `isRecording` property's `didSet`
  observer when the new value equals the old; theme-change-repaint is
  driven by `observeTheme`, whose initializer applies the current palette
  synchronously before the initializer's own first `refreshText()` call
  runs; `pending-shortcut-priority` and the placeholder-display
  requirements are implemented as `didSet` observers on `pendingShortcut`
  and `displayedShortcut` that both call the same `refreshText()` routine.
  The corner radius is `layer?.cornerRadius = 5`; the border width is
  `layer?.borderWidth = 1`; the label's leading/trailing insets are Auto
  Layout constraints of `constant: 6`/`constant: -6`, centered vertically
  via `centerYAnchor`; the fixed height and minimum width are
  `heightAnchor.constraint(equalToConstant: 22)` and
  `widthAnchor.constraint(greaterThanOrEqualToConstant: 132)`. The font is
  `palette.font(.button)`, which resolves via
  `theme.typography.style(.button).nsFont(scaledSize:)` to `FontStyle(size:
  13, weight: .medium)` in `ThemeTypography.swift`. No
  `setAccessibilityRole`, `setAccessibilityLabel`, or
  `setAccessibilityTitleUIElement` call, and no
  `NSAccessibility.post(element:notification:)` call, appears anywhere in
  source. The default key-handling fallback (when neither an override
  claims the event) is AppKit's own `NSResponder.keyDown` default, which
  for a plain `NSView` with no further responder-chain handler typically
  produces the system alert beep. The manual recording-stop operation's
  focus-check guard is `window?.firstResponder === self`, evaluated through
  optional chaining so a deallocated window or absent first responder
  evaluates `false` without crashing. Both localized-string literals are
  assigned directly to an AppKit `stringValue`, which — unlike a string
  literal passed to a SwiftUI `Text`/`Label` (a `LocalizedStringKey`) —
  does not localize on its own; source contains no `NSLocalizedString` or
  string-catalog key reference for either. Every appearance change
  (`refreshText()`, `applyTheme()`) is an instantaneous property
  assignment with no `CATransaction`/animator-proxy call. Neither this
  component's own source nor the `SemanticPalette` color-resolution path
  it calls into reads `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`.
  Persistence, were the hosting row to add any, would typically go through
  `UserDefaults` or an equivalent store — this component itself performs
  none.
- **WinUI 3**: Build a custom templated `Control` (or `UserControl`) styled to
  look like a `TextBox` — a rounded `Border` (`CornerRadius="5"`, matching this
  recipe's 5pt corner radius exactly, rather than Fluent's small-control
  default of 4) hosting a centered `TextBlock` — and NOT an actual `TextBox`,
  for the same reason the source avoids `NSTextField`: WinUI's
  `TextBox` consumes character input through its own composition/IME
  pipeline and would swallow the very keys being recorded. Override
  `OnPreviewKeyDown` — the WinUI analog of `performKeyEquivalent`, since it
  runs before a `KeyboardAccelerator` or menu can claim a Ctrl-chord — and
  set `e.Handled = true` for every combination the control decides to
  capture; read modifiers from `Windows.System.VirtualKeyModifiers` in place
  of `NSEvent.modifierFlags`. Drive the recording boolean from `GotFocus`/
  `LostFocus` (the WinUI analog of gaining/losing focus)
  with `IsTabStop="True"`, and leave `e.Handled =
  false` for a bare `VirtualKey.Tab` so normal `XYFocusKeyboardNavigation`
  still moves focus, mirroring unmodified-tab-passthrough. Represent a
  captured chord as a `VirtualKeyModifiers` + `VirtualKey` pair — WinUI has no
  ready-made equivalent to `KeyboardShortcuts.Shortcut` — and format it for
  display by joining modifier names with `+`, mirroring `Shortcut.description`.

