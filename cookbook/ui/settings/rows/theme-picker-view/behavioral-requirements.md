
- **composes-theme-choice-popup**: Component MUST construct a private
  choice control whose view model is derived from the injected theme
  store.
- **composes-theme-preview**: Component MUST construct a private theme
  preview using its default, no-argument construction (no theme passed at
  construction time).
- **stacks-popup-above-preview**: Component MUST arrange the choice control
  and the preview, in that order, inside a single leading-aligned vertical
  stack with 10pt of spacing between them.
- **pins-stack-to-view-edges**: Component MUST pin that stack's
  top/leading/trailing/bottom edges directly to its own edges with no
  additional inset, so the stack fills the component exactly (see Platform
  Notes for the mechanism used to pin it).
- **derives-choices-from-injected-store**: The theme-choice view model MUST
  set the control's title to the literal "Theme" and its choices to one
  entry per built-in and custom theme in the store, each mapping a theme to
  a label/value pair of its name and its id, in the store's own theme
  ordering (built-ins first, then custom themes).
- **defaults-to-the-persisted-theme-store**: Component's theme-store
  parameter MUST default to the app's persisted theme store — the one that
  reads and writes custom themes and the active theme id through the
  shared settings store.
- **renders-initial-preview-synchronously**: Component MUST render the
  preview's first sample synchronously during initialization: the
  palette-observing subscription's apply step MUST run before
  initialization completes, showing the current palette's theme
  immediately.
- **resyncs-preview-on-theme-change**: WHEN the theme manager posts its
  theme-change notification, the component's subscription MUST show the
  newly current palette's theme in the preview again.
- **resyncs-preview-on-matching-scope-change**: WHEN a theme-scope change
  notification is posted for the theme scope identical to the view's own
  resolved scope (resolved by walking the view's ancestor chain for the
  nearest scope-providing ancestor, or the app-wide scope if none exists),
  the component's subscription MUST show the palette's theme in the preview
  again.
- **ignores-non-matching-scope-change**: WHEN a theme-scope change
  notification is posted for a theme scope other than the view's own
  resolved scope, the component MUST NOT refresh the preview.
- **commits-selection-through-the-active-theme-setting**: WHEN the user
  picks a different item in the choice control, the resulting write
  (performed inside the choice control itself) MUST land in the shared
  active-theme setting — the same setting the theme-choice view model was
  constructed against — with no separate persistence step of the
  component's own.
- **decouples-preview-refresh-from-selection-commit**: Component MUST NOT
  refresh the preview directly from the choice control's selection path;
  no call from the control to the preview exists at all — the preview
  refreshes only through the palette-observing subscriptions described
  above (see Edge Cases for the refresh timing that results).
- **keeps-constituent-views-private**: Component MUST expose no accessor —
  public property, method, or computed value — that lets an external
  caller read or mutate the composed choice control, the composed preview,
  or the palette-observer subscription.
- **retains-the-palette-observer-for-its-lifetime**: Component MUST retain
  the constructed palette-observing subscription for its own lifetime, so
  the subscription (and the preview refresh it drives) lives exactly as
  long as the view does.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

