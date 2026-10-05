
**Decision**: The help button is shown for every panel a split hosts, based
solely on the show-help-button setting and whether a help presenter is
assigned — never on whether the panel currently on screen has any help
content.
**Rationale**: per the source's own comment on `updateHelpButton()`, it used
to come and go with `help != nil`, which "put a control in the corner of
some panels and not others and made the drawer look like a property of
the panel rather than of the window."
**Approved**: pending

**Decision**: The anchor-claiming step re-runs unconditionally on every
help-presenter assignment and every show-help-button change, rather than
claiming the anchor once at construction.
**Rationale**: per the source's own comment on `claimHelpAnchorIfShown()`,
claiming the anchor only once meant a later help-presenter reassignment
"silently took it back" from whoever held it, "and handed a popover
presenter a hidden, zero-size view to hang off."
**Approved**: pending

**Decision**: Route chrome outside this view (e.g. a toolbar help button)
through a dedicated external visibility-change callback rather than
sharing the help presenter's own visibility-change notification directly.
**Rationale**: per the source's own comment on this callback, the
presenter's own visibility-change notification "has exactly one slot" and
this view claims it for its own inline button; anything else that needs
the same notification has to be told by whoever holds that slot rather
than overwriting it.
**Approved**: pending

**Decision**: The help button's tint contrast against its background is whatever the theme's accent and secondary-text colors give; the view performs no contrast check, and no per-theme audit against WCAG AA's 3:1 non-text minimum exists.
**Rationale**: Checked `PanelHostView.swift`: the refresh sets `helpButton.contentTintColor` from `palette.accentColor` or `palette.secondaryTextColor` and nothing measures the result. Closing the gap would take a per-theme contrast audit of both roles or a contrast floor in their derivation.
**Approved**: pending

