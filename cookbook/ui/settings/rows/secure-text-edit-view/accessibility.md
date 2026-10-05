
- **Role/trait**: Inherited unmodified from the text edit row — no
  explicit accessibility role override appears in either file; the
  platform's secure text field carries its own built-in secure-text-field
  accessibility role.
- **Label requirements**: Neither the text edit row's construction (which
  this component inherits unmodified) nor this component's own source
  links the field's accessible name to the label — unlike the sibling
  checkbox row (adtoolkit://cookbook/ui/settings/rows/checkbox-view),
  which links its switch to its label for exactly this reason (the
  platform gives a bare switch no name). Without that link, a screen
  reader announces the field as an unnamed secure text field rather than
  by the row's title.
- **Announce state changes**: Inherited unmodified from the text edit row
  — the component has no loading state and never disables itself in
  source; masked characters being typed or deleted are announced through
  the platform's own native accessibility value reporting.
- **Minimum tap target**: Inherited unmodified from the text edit row —
  this is a pointer/trackpad-driven control composition (no touch input
  path in source); the 44×44pt minimum is touch guidance, not a
  pointer-interface requirement.
- **Contrast**: Inherited unmodified from the text edit row — the label
  and the field's typed-text color both resolve to the theme's
  `primaryText` role, and placeholder text resolves to `placeholderText`,
  which is guaranteed only a 1.6:1 contrast floor against the background
  (see `adtoolkit://cookbook/ui/settings/rows/text-edit-view#design-decisions`
  and **contrast-ratio** in Compliance below). Whether an active theme's
  actual resolved colors clear WCAG 2.1 SC 1.4.3's 4.5:1 threshold for
  body text is a property of the chosen theme, not of this component.

