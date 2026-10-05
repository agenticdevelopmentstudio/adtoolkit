
**Decision**: Give the sidebar's own top slot to the search field and remove
the sidebar title entirely, rather than showing a titled sidebar with search
below it.
**Rationale**: this matches System Settings' shape (source comment); the
name of what is on screen is shown once, in the toolbar's panel-title item
beside the back/forward control, exactly where a reader is already looking
to change it — a separate sidebar title would be a second answer to the same
question.
**Approved**: pending

**Decision**: Sort panels alphabetically, always, with no host-supplied
ordering option.
**Rationale**: the panels in a settings window are unrelated destinations,
and the only thing a reader hunting for one of them knows is its name;
whatever order a host happened to register panels in is an order only the
host can see (source comment on `sortsPanelsByTitle`).
**Approved**: pending

**Decision**: Represent back/forward as one two-segment `NSSegmentedControl`
rather than two independent `NSButton`s.
**Rationale**: it is one control with one meaning — where in the navigation
trail the reader is — and a single shared bezel is how System Settings
expresses that (source comment on `navigationControl`).
**Approved**: pending

**Decision**: `activatesOnShow` defaults to `true`, with an open override
point for hosts that don't want it.
**Rationale**: a settings window is normally opened to be used immediately,
and shown from an `LSUIElement`/menubar host the base `showWindow()` still
leaves the window visible but non-key, so its sidebar selection and text
fields don't respond until the user clicks it first; defaulting to
activation avoids that dead first click for the common case, while the
override keeps the behavior optional rather than forcing it on every
consumer (source comment on `activatesOnShow`).
**Approved**: pending

**Decision**: Under `QuietWindowPresentation`, make the window key without
activating the app or ordering it above other applications' windows.
**Rationale**: an automated session driving the app still needs the sidebar
selection and text fields to respond, which requires the window to be key,
but must not steal focus or draw over whatever the person at the keyboard is
doing — that is the entire distinction this file draws between a settings
window "opened to be used" and one "opened to be driven" (source comment on
`showWindow()`).
**Approved**: pending

**Decision**: Wire the help button reference, its theme observer, and the
help-anchor view only when `willBeInsertedIntoToolbar` is `true`.
**Rationale**: AppKit calls the toolbar item factory again to build a
customization-palette sample and on every toolbar rebuild; adopting one of
those non-live copies would point all three at a button that is never on
screen, leaving the real, visible help button unthemed and unreported
(source comment on the `.settingsHelp` case).
**Approved**: pending

**Decision**: Whether to update the class doc comment (which still shows
`override func makeSettingsPanels() -> [ComposableSettings.SettingsPanelViewController]`)
to describe `settingPanels`, or to restore a `makeSettingsPanels()` override
point, is not yet settled.
**Rationale**: `SettingsWindow.swift` illustrates subclassing
through a `makeSettingsPanels()` override that does not exist anywhere in
the class — the only subclass-facing configuration surface this version
actually exposes is the `settingPanels` property (see Overview and
Configuration). This is a documentation/implementation mismatch in the
source, not a behavior this recipe can decide on its own; it belongs to
whoever maintains `SettingsWindow.swift`.
**Approved**: pending

**Decision**: The window computes and asserts no contrast ratio between the header-bar text and tint roles and the surface behind them.
**Rationale**: The title and help colors come straight from the theme palette (`ThemedLabel` with the primary-text role; the help button reads its tint from the palette on demand), and `SettingsWindow.swift` contains no contrast computation. Closing the gap takes a theme-level contrast audit of the palette's roles against the surfaces they are drawn over, not a change to the window.
**Approved**: pending

