
- Role/traits: standard window with title-bar close/minimize/zoom controls;
  toolbar and titlebar-accessory controls are plain buttons (custom-view
  toolbar items, since a toolbar item is not itself directly accessible)
  and a system-style search field.
- Accessibility identifiers: the search field and help button carry the
  toolbar identifiers `project.toolbar.search` and `project.toolbar.help`;
  the titlebar accessories carry `project-window.arrange-button` and
  `project-window.project-settings-button`.
- Label requirements: the help button's accessibility description is fixed
  at "Help" and does not change when its glyph/tooltip swap for open vs.
  closed; the arrange and settings buttons carry the accessibility
  descriptions "Arrange Panes" and "Project Settings"; the search field's
  placeholder is the search target's own placeholder text or "Search" when
  none applies.
- Announce state changes: the help toggle communicates its open/closed
  state through symbol shape (outline vs. filled) and tooltip text, not
  tint alone; the arrange toggle communicates its state through the
  button's own pressed/active visual state, in addition to tint.
- Minimum control size: this is a pointer-driven layout with no mandated
  minimum touch-target size; the titlebar accessory buttons are built at
  36×24pt and the toolbar icon buttons follow the platform's standard
  icon-only sizing, consistent with this codebase's other toolbar/titlebar
  controls rather than a value this component decides on its own.
- Keyboard/focus: the titlebar and toolbar buttons are ordinary
  keyboard-focusable controls (Space/Return activate); the search field has
  normal text-field key handling; the arrange action is additionally
  reachable through any menu item bound to the arrange-mode action,
  validated by the platform's own menu-validation mechanism.
- Color/contrast: chrome colors are read from the shared theme palette;
  contrast is a design-system-level concern outside this window's own
  decisions, per
  `agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages`.

