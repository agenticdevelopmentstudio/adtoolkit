# Opening a chat window (Apple)

Everything a tool needs to put a persona chat on screen lives in
`AgenticDeveloperToolkitUI`. A host supplies three things — a backend, a
name to save settings under, and (optionally) a backdrop — and gets the
same window every other tool's chat is: no title bar furniture, a
translucent surface, a themed border, and a gear at the trailing edge
holding the window's own appearance switches.

Nothing about that window is olylo's. Olylo is one host; this document is
for the next one.

## The smallest host

```swift
import AppKit
import AgenticDeveloperToolkit
import AgenticDeveloperToolkitUI

let viewModel = ObservableChatViewModel(
    backend: myBackend,                  // any `Backend`
    localParticipantID: "user")

let controller = ChatWindowController(
    viewModel: viewModel,
    localParticipantID: "user",
    configuration: ChatWindowConfiguration(
        title: "Scout",                  // Window menu / accessibility
        defaultsNamespace: "scout.chat", // where this window's settings live
        appearanceTitle: "Scout Window"))// caption at the top of the gear panel

controller.showWindow(nil)
```

That is the whole integration. The window opens at its saved frame (or
460×620 the first time), restores the text size and transparency it was
last left at, takes keyboard focus in the composer, and re-takes it every
time it becomes key.

## `ChatWindowConfiguration`

| Field | What it decides |
|---|---|
| `title` | The window's title. Hidden in the bar, but read by the Window menu, Mission Control and VoiceOver. |
| `defaultsNamespace` | Prefix for this window's saved settings. **Two windows with different namespaces remember their text size and transparency separately.** Two with the same namespace share them — which is the only way to opt into shared settings, and it has to be asked for. |
| `appearanceTitle` | Caption at the top of the gear's panel: the window's name in the reader's language. |
| `contentSize` | Size the window opens at before a saved frame exists. Defaults to 460×620. |
| `chrome` | Which face the chat wears — see below. |
| `backdropToggleTitle` | What the gear calls the backdrop switch. Only shown when the window has a backdrop. Defaults to "Background animation"; olylo says "Rain". |

The type is `Sendable` and describes *what* a window is. A view is not a
value, which is why the backdrop is a separate argument rather than a
field on it.

## Chrome

`InlineChatChrome` is the handful of things the CSS themes vary that a
palette cannot express — a send glyph, a prompt glyph, a block caret, the
divider, the composer's border and radius, the placeholder. The default
value is the stock look; `.terminal` is the flat phosphor look web's
`old-school-terminal`, `terminal` and `matrix` themes share:

```swift
ChatWindowConfiguration(
    title: "Scout",
    defaultsNamespace: "scout.chat",
    appearanceTitle: "Scout Window",
    chrome: .terminal)
```

A host that wants one detail changed starts from a preset and edits it —
`var chrome = InlineChatChrome.terminal; chrome.inputPlaceholder = "…"` —
rather than defining a fourth look.

## Colours: the theme, never a literal

Colours come from the active theme through `SemanticPalette`, and a view
gets them by asking its own scope:

```swift
observer = ThemePaletteObserver(host: someView) { [weak self] palette in
    self?.tint = palette.nsColor(.accent)
}
```

`host:` is what scopes it. A view inside a chat resolves *that chat's*
`ThemeScope`; a loose view falls back to `ThemeScope.app`. Hold the
observer — it keeps its subscription only as long as someone keeps it —
and expect the palette to arrive once, synchronously, on construction, so
there is no unthemed first frame.

Text size lives on the scope for the same reason. Dragging one window's
slider, or pressing ⌘+ in it, changes that window's text and no other's.

## Per-window settings

`ChatWindowAppearanceController` owns the gear, the switches behind it,
and the `UserDefaults` keys under `defaultsNamespace`. It is created by
`ChatWindowController` and reachable as `controller.appearance`:

- `appearance.defaults` — the saved values (`textScale`,
  `transparency` as **0–100**, `isFloating`, `showsBackdrop`). A window
  saved under the pre-percentage alpha scale migrates on read.
- `appearance.nudgeTextScale(by:)` — one tenth per step, clamped, `0`
  resets to the theme's own size. Already wired to ⌘+/⌘− inside the chat
  view; call it directly only from a host's own menu item.
- `appearance.install(leading:)` — called for you. Pass `leading:` views
  to put a host's own chrome in the title bar alongside the gear rather
  than instead of it.

Transparency is a percentage of *the surface*, not of the window: the
text, the gear and the controls stay fully opaque at every setting.

## A backdrop

Anything can sit behind the transcript. Pass a view that conforms to
`AnimatedBackdrop` and the gear grows a checkbox — defaulting to on —
that starts and stops it:

```swift
public protocol AnimatedBackdrop: AnyObject {
    func startAnimating()
    func stopAnimating()
}
```

Olylo's is 40 lines: it subclasses `WhatsNowEffects.MatrixRainView`,
reads four colours off the palette, and dims itself so the transcript
reads over it. The effect itself knows nothing about ADT, themes or
olylo — which is the shape to copy. A backdrop over a *translucent*
window should also fade by erasing rather than by painting, or a
per-frame wash of an opaque colour will quietly turn the window opaque
within a second.

## Adding host behaviour

`ChatWindowController` is `open`. Subclass it for a connect ritual, a
status-bar item, a scripted arrival — anything that is this tool's and
not every tool's. `controller.chatView` is public so a host can drive the
transcript directly.

The window itself needs no subclass. If you find yourself reaching into
it to change how it looks or how it saves, that is a signal the knob
belongs in `ChatWindowConfiguration` or `InlineChatChrome` — add it there
so the next host gets it too.
