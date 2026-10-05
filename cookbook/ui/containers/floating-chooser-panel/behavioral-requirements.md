
- **hosts-content-as-child-controller**: The panel MUST add the hosted
  content as a child of an intermediate container, and that container — not
  the hosted content itself — MUST be the window's top-level content.
- **pins-content-to-container-edges**: The hosted content's view MUST be
  constrained to the top, leading, trailing, and bottom edges of the
  container, with zero additional padding.
- **uses-titled-panel-style-mask**: The panel's window MUST use a titled
  panel style that supports closing and lets hosted content extend into the
  title-bar area.
- **hides-title-text**: The window's title text MUST be invisible, and the
  title bar's background MUST be transparent.
- **hides-standard-window-buttons**: The window's close, minimize, and zoom
  title-bar buttons MUST be hidden, even though the title bar style supports
  a close button.
- **floats-above-normal-windows**: The window MUST float above normal
  application windows.
- **joins-all-spaces-and-full-screen-auxiliary**: The window MUST remain
  visible on every virtual desktop/workspace, and MUST be treated as an
  auxiliary window while another window is in full-screen mode.
- **is-not-user-resizable**: The window MUST NOT be resizable by the user.
- **survives-close-without-releasing**: Closing the panel MUST NOT
  release/destroy the underlying window; the same window instance MUST
  remain reusable across repeated close/show cycles.
- **rejects-coder-initialization**: The controller MUST be constructible only in code, from a hosted content component and a content rect. Constructing it from a serialized or archived representation MUST be refused as a programmer error that terminates, producing no instance.
- **guards-show-against-missing-window**: Showing the panel MUST return
  immediately, performing no positioning, activation, or focus work, if the
  underlying window does not exist.
- **positions-on-pointer-screen**: Showing the panel MUST position it on
  the screen whose frame contains the current pointer location.
- **falls-back-to-main-screen**: If no screen contains the pointer
  location, positioning MUST fall back to the main screen.
- **falls-back-to-centering-without-visible-frame**: If the resolved screen
  has no usable visible area — including when no screen contains the
  pointer location and there is no main screen either — the panel MUST be
  centered on the screen instead of using the pointer-relative calculation.
- **centers-horizontally-on-screen**: The panel's horizontal position MUST
  center it within the target screen's visible area: horizontal position =
  the visible area's horizontal midpoint minus half the panel's width.
- **offsets-top-edge-by-fixed-fraction**: The panel's top edge MUST sit 20%
  of the visible area's height below the top of the visible area.
- **activates-app-before-showing**: Showing the panel MUST activate the
  application before ordering the panel's window to the front.
- **respects-quiet-activation**: Activation during showing MUST go through
  a quiet-aware activation path that skips forcibly activating the app
  (bringing it to the front over other apps) when quiet-window presentation
  is enabled.
- **shows-and-takes-key-before-initial-focus**: Showing the panel MUST make
  the window key and bring it to the front before calling the initial-focus
  hook, so the window MUST already have keyboard focus when that hook runs.
- **reshows-idempotently**: Showing an already-open panel again MUST
  reposition and refocus the same window rather than creating a second
  window.
- **defaults-initial-focus-hook-to-no-op**: The initial-focus hook MUST do
  nothing in the base implementation; an extending component that needs
  initial-focus behavior MUST override it.
- **dismisses-on-focus-loss-by-default**: The base implementation's
  focus-loss dismissal setting (`dismissesOnFocusLoss`) MUST default to
  `true`.
- **closes-on-focus-loss-when-enabled**: When focus-loss dismissal is
  enabled, the window is visible, and no dismissal is already in progress,
  losing key status MUST close the panel.
- **ignores-focus-loss-when-disabled**: When focus-loss dismissal is
  disabled, losing key status MUST NOT close the panel.
- **ignores-focus-loss-while-already-dismissing**: While a dismissal is
  already in progress (`isDismissing == true`), losing key status MUST NOT
  close the panel again.
- **ignores-focus-loss-when-not-visible**: If the window is not visible,
  losing key status MUST NOT close the panel.
- **guards-close-against-reentrancy**: Closing the panel MUST return
  immediately without performing the underlying close if a dismissal is
  already in progress (`isDismissing == true`).
- **resets-dismissing-flag-after-close**: Closing the panel MUST clear
  `isDismissing` back to `false` after the underlying close completes.
  Only the outer call — the one that found `isDismissing == false` and set
  it to `true` — reaches this reset; a nested, reentrant call returns at
  the reentrancy guard before it, so it never touches the flag. The next
  dismissal of a re-shown panel MUST therefore be treated as a fresh entry.
- **calls-panel-will-close-on-window-close**: The window closing MUST run
  the pre-close hook exactly once per dismissal.
- **defaults-panel-will-close-hook-to-no-op**: The pre-close hook MUST do
  nothing in the base implementation; an extending component that needs
  teardown behavior on close MUST override it.
- **decides-size-via-subclass-content-rect**: The window's initial size
  MUST come entirely from the `contentRect` value an extending component
  supplies at construction; the base implementation MUST NOT compute or
  default a size of its own.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

