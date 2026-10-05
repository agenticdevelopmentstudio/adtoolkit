
- **SwiftUI**: There is no direct `NSButton`-subclassing counterpart. On macOS 15+, prefer [`.pointerStyle(.link)`](https://developer.apple.com/documentation/swiftui/view/pointerstyle%28_:%29) on a `Button` — SwiftUI's native pointing-hand affordance. On earlier macOS targets, apply `.onHover { isHovering in if isHovering { NSCursor.pointingHand.set() } else { NSCursor.arrow.set() } }` instead; verify in a non-key panel that the hover callback still fires there, since SwiftUI's documentation does not state whether `onHover` depends on key-window status the way `resetCursorRects()` does.
- **Compose**: On Compose for Desktop, apply `Modifier.pointerHoverIcon(PointerIcon.Hand)` to the composable; verify in a non-key panel that the pointer icon still applies there, since Compose Desktop's documentation does not state whether pointer-icon handling depends on window focus the way AppKit's cursor rects do.
- **React/Web**: Set CSS `cursor: pointer` on the element. Browsers already display the pointer cursor over an element in any window, focused or not, so there is no equivalent to the source's key-window workaround to port.
- **AppKit / UIKit** (source platform): Source file
  `packages/apple/AgenticToolkit/CoreUI/PointingHandButton.swift` is
  macOS-only (`import AppKit`); there is no iOS/UIKit counterpart, since
  UIKit has no cursor-rect or `NSCursor` concept — cursors do not apply to
  a touch interface. The class subclasses `NSButton` and layers an
  `.activeAlways` `NSTrackingArea` (`mouseEntered`/`mouseMoved`/
  `mouseExited`, held as a private `hoverArea` property) on top of the
  ordinary `resetCursorRects()` override, specifically to also cover
  floating, non-key panels that `resetCursorRects()` alone does not reach.
  `cursor-rect` is implemented as `addCursorRect(bounds,
  cursor: .pointingHand)` inside `resetCursorRects()`.
  `tracking-area-replacement`/`always-active-tracking` are implemented in
  an overridden `updateTrackingAreas()`, which calls
  `super.updateTrackingAreas()` first, removes `hoverArea` via
  `if let hoverArea { removeTrackingArea(hoverArea) }` when it exists, and
  then registers a new `NSTrackingArea(rect: bounds, options:
  [.mouseEnteredAndExited, .mouseMoved, .activeAlways], owner: self,
  userInfo: nil)`. `enter-cursor`/`move-cursor`/`exit-cursor` are
  `mouseEntered(with:)`/`mouseMoved(with:)` calling
  `NSCursor.pointingHand.set()`, and `mouseExited(with:)` calling
  `NSCursor.arrow.set()`. None of the five overridden methods reads
  `isEnabled`, and no `bezelStyle`, `isBordered`, `attributedTitle`, or
  `controlSize` customization appears anywhere in source.
- **WinUI 3**: Subclass `Button` and set `ProtectedCursor = InputSystemCursor.Create(InputSystemCursorShape.Hand)` in the constructor. WinUI applies and restores the protected cursor automatically as the pointer enters and exits the control, so no `PointerEntered`/`PointerExited` handlers are needed. `ProtectedCursor` is `protected`, so this must be set from within a `Button` subclass, not from a containing element — a WinUI 3 port needs only this one constructor assignment, not a second, always-active tracking mechanism.
- **UI-thread confinement**: `confines-to-ui-thread` — the type declares no isolation of its own; it is an `NSButton` subclass and so inherits the main-actor isolation AppKit's view classes carry, which makes construction or mutation from off the main actor a compile-time error under strict concurrency checking.

