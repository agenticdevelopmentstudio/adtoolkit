
- **SwiftUI**: There is no SwiftUI-native terminal emulator equivalent to
  `LocalProcessTerminalView`; wrap it (or another terminal engine) in an
  `NSViewRepresentable`, exposing `CaretAppearance` as a `Binding` the
  representable's `updateNSView(_:context:)` writes into the wrapped
  `ThemedTerminalView`'s `caretAppearance` property on every SwiftUI
  update, rather than re-deriving the hollow/filled decision in SwiftUI
  itself.
- **Compose**: Wrap an Android terminal-emulation view (there is no
  Jetpack Compose-native equivalent) in an `AndroidView`, and reproduce
  the caret decision as a small `Drawable`/custom `View` overlay whose
  stroke is toggled on/off the same way this file toggles
  `layer.borderWidth`; drive it from a `mutableStateOf<CaretAppearance>`
  the same way `caretAppearance`'s `didSet` drives `updateCaret()`.
- **React/Web**: xterm.js exposes `cursorStyle: 'block' | 'underline' |
  'bar'` and theme colors (`cursor`, `cursorAccent`) but no built-in
  hollow-block style either; reproduce the outline by setting the cursor
  cell's CSS to a transparent background with a `1px solid`
  outline/border color, toggled by the same
  `isAlwaysHollow`/`marksActivePane`-equivalent booleans, and drive
  `cursorAccent` the way this file drives `caretTextColor`.
- **AppKit / UIKit (source)**: `ThemedTerminalView.swift` is macOS-only
  (`import AppKit`); there is no UIKit counterpart in this file. It
  subclasses SwiftTerm's `LocalProcessTerminalView`, is declared
  `internal` specifically to avoid an Objective-C header conflict with
  the Swift-only `SwiftTerm` module, locates SwiftTerm's private caret
  subview by matching its runtime type name's `"CaretView"` suffix (with
  a weak, superview-validated cache), and separates "recompute the
  hollow/filled decision" (`updateCaret()`, run on appearance/window/notification
  changes) from "just repaint the border" (`applyOutline()`, run on
  every SwiftTerm cursor callback) to avoid rewriting SwiftTerm's caret
  color properties on every cursor movement. The class itself is
  declared `@MainActor`, confining every property and method to the main
  actor, and overrides `init?(coder:)` to `fatalError`, since it is
  never constructed from a storyboard or nib.
- **WinUI 3**: If hosting a real terminal buffer,
  `Microsoft.Terminal.Control.TermControl` (from the Windows Terminal
  control package) is understood to expose some cursor-styling options
  through its settings, but this recipe has no cited source confirming
  whether it offers anything like a hollow-outline style, so treat that
  specific claim as unverified. Independent of what `TermControl` offers
  natively, the same border-overlay technique used here can be
  reproduced generically: track the active cell's caret with a `Border`
  element layered over the terminal surface, and toggle between a filled
  state (`Border.Background` set to the caret color, `BorderThickness="0"`)
  and a hollow state (`Border.Background` set to `Transparent`,
  `BorderThickness="1"`, `BorderBrush` set to the caret color) through a
  `VisualStateManager` `VisualState`, mirroring this file's
  `borderWidth`/`borderColor` toggle. Use a shared static event (or
  `WeakEventManager`) as the WinUI analog of
  `NotificationCenter.default.publisher(for: ComposableTabsActivePane.didChangeNotification)`
  for broadcasting an active-pane change to every terminal control that
  needs to repaint its caret — this class has no key-window handling of
  its own to draw an analogy from.

