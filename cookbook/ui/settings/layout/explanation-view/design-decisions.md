
**Decision**: (AppKit/UIKit) The label overrides the shared `ThemedLabel`
type's default single-line, clipped, non-wrapping configuration
(`cell?.wraps = true`, `cell?.usesSingleLineMode = false`, `lineBreakMode =
.byWordWrapping`, `maximumNumberOfLines = 0`) instead of accepting
`ThemedLabel`'s defaults.
**Rationale**: source comments explain that `ThemedLabel` is deliberately
single-line by default "so a caption in a toolbar doesn't ask for two
lines' height," and that "a blurb is the other case, and has to say so" —
without these overrides, `lineBreakMode`/`maximumNumberOfLines` are ignored
while the cell is in single-line mode, and the label would (per the source
comment) "set its wrap policy and then [run] off the right edge anyway."
**Approved**: pending

**Decision**: (AppKit/UIKit) The label's horizontal content-compression-
resistance and content-hugging priorities are both lowered to
`.defaultLow`.
**Rationale**: source comments state that "a wrapping label still reports
its one-line intrinsic width unless it is allowed to yield
horizontally — otherwise a long blurb forces the whole panel (and the
settings window) as wide as the text," so the label is deliberately let to
compress and wrap to the available width instead.
**Approved**: pending

**Decision**: (AppKit) Force a fatal error from both `init(frame:)` and
`init(coder:)`, leaving `init(withText:)` as the only usable initializer.
**Rationale**: the view has no meaningful default state — it cannot render
anything without a `text` string — so both inherited `NSView` initializers
that could construct it without one are intentionally disabled rather than
left to produce a blank row (`requires-text-at-construction`).
**Approved**: pending

**Decision**: (AppKit) `init(frame frameRect: NSRect)`'s fatal-error
message in source is the literal string `"init(frame frameRect: NSRect"`,
missing a closing parenthesis and not following the `"init(coder:) has not
been implemented"` sentence form the sibling `init?(coder:)` message uses.
**Rationale**: a known issue, documented here rather than smoothed over —
the string reads as a truncated fragment of the initializer's own signature
rather than a complete sentence, and is very likely an unintentional typo.
The source is unchanged for this recipe, but this is not a decision worth
reproducing: a well-formed message (following the sibling `init?(coder:)`
sentence form) is the correct target, and any implementation — including a
future fix upstream — SHOULD use one rather than copying this exact
malformed string.
**Approved**: pending

**Decision**: (AppKit) The view provides no `update`/`setText` method;
callers that need to change the text after construction reassign
`label.stringValue` directly (see Configuration).
**Rationale**: every existing call site that updates the view's text after
construction already does this (e.g. `ExtensionsBrowsePanel.swift`), and
`NSTextField.stringValue`'s setter already triggers the intrinsic-size
invalidation a wrapping label needs — an added `update(text:)` wrapper
would only duplicate behavior `NSTextField` already provides for free.
**Approved**: pending

**Decision**: The explanation label's contrast is whatever the theme's secondary-text role resolves to; the view performs no contrast check, and the theme guarantees only a 3.0 floor against WCAG's 4.5:1 for 11pt text.
**Rationale**: Checked `ExplanationView.swift` and `SettingsLabels.swift` (`makeValueLabel`): the label is a `ThemedLabel` with the `.secondaryText` role and `.caption` text role, and no code in the view measures or raises contrast. Closing the gap would take either a 4.5:1 floor in the secondary-text derivation or a per-theme contrast audit.
**Approved**: pending

