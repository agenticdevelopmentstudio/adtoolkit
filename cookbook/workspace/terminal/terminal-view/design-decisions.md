
**Decision**: The class is declared `internal` rather than `public` or `open`.
**Rationale**: Per source: "a *public* NSView subclass would name `LocalProcessTerminalView` in the framework's generated Objective-C header, which then cannot find the Swift-only `SwiftTerm` module."
**Approved**: pending

**Decision**: `showCursor(source:)` and `cursorStyleChanged(source:newStyle:)` call only `applyOutline()`, reusing the last-computed `isHollow`, rather than calling `updateCaret()` (which would recompute `isHollow` and rewrite `caretColor`/`caretTextColor`).
**Rationale**: Per source: "Deliberately *not* on the `showCursor` path, which runs on every cursor movement: the two colours below are properties SwiftTerm holds on to, so they want writing when the answer changes rather than once a frame."
**Approved**: pending

**Decision**: SwiftTerm's caret subview is located by matching a runtime type-name suffix (`"CaretView"`) rather than a typed accessor, and the match is weakly cached.
**Rationale**: Per source: "SwiftTerm adds its caret as a direct subview but exposes no accessor for it, so it is recognized by class name... Cached, because the search is not free and the caller is not rare... a per-keystroke cost for an answer that changes when SwiftTerm rebuilds its subviews and at no other time."
**Approved**: pending

**Decision**: `confines-to-ui-thread` has no runtime conformance vector; it is verified by the Swift compiler's `@MainActor` isolation checking at compile time.
**Rationale**: A MUST requirement enforced entirely by the type system needs no runtime test to demonstrate — violating it is a compile error, not an outcome a test vector could observe.
**Approved**: pending

**Decision**: `ThemedTerminalView` relies on `ComposableTabsActivePane.isInActivePane` treating a view with no `ComposableTabsPaneBackgroundView` ancestor as "in the active pane" (see `adtoolkit://cookbook/ui/layout/composable-tabs/active-pane#requirements/view-outside-any-pane-counts-as-active`), so `marksActivePane` never hollows such a caret.
**Rationale**: The consequence for this file: a `ThemedTerminalView` used outside any composable-tabs pane with `marksActivePane == true` stays filled rather than hollow, because it is never "not in" an active pane by that dependency's own rule. The rule itself, and why it treats an unclaimed view as active, belongs to `composable-tabs-active-pane` and is not restated here.
**Approved**: pending

**Decision**: `CaretAppearance.color` and `CaretAppearance.textColor` default to the literal `NSColor.white` rather than a semantic theme-color token.
**Rationale**: No rationale is given in source for this specific choice, and no call site in this codebase overrides it with a semantic token — nothing marks it deliberate, and nothing records a plan to pay it down. It should become whichever semantic accent/foreground color token the app's theme system exposes for this purpose once one exists; see the `platform-theming` compliance status below.
**Approved**: pending

**Decision**: The caret color and text color are applied verbatim from the caller with no contrast computation against the terminal background; no contrast calculation exists in the view's source.
**Rationale**: Whether a theme's caret color meets a minimum contrast ratio depends on the theme and palette values passed in at the call site. Closing the gap means a contrast check at that call site or in the theme layer, or a clamp inside the view.
**Approved**: pending

