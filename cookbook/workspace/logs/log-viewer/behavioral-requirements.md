
- **layout-stack**: The component MUST render, top to bottom,
  a toolbar strip, a 1pt divider, and the hosted log view, filling the
  component's root view.
- **container-background**: The component MUST fill the root
  container with the `.windowBackground` theme role.
- **minimum-content-size**: The component MUST constrain the root
  view's width and height to each be at least `minimumContentSize` (default
  `600×400`, overridable).
- **fixed-toolbar-height**: The component MUST give the toolbar strip a fixed
  height equal to `toolbarHeight` (default `40pt`, overridable).
- **divider-below-toolbar**: The component MUST place a 1pt, `.divider`-role
  separator directly below the toolbar, spanning the root view's leading and
  trailing edges.
- **log-view-fills-remaining-space**: The component MUST size the hosted
  log view to fill the root view's leading, trailing, and bottom edges below
  the divider.
- **leading-toolbar-items-rendered**: The component MUST render every view
  returned by the leading-toolbar-items hook, in the order returned, in a
  single horizontal stack (8pt spacing, vertically centered) pinned 12pt
  from the toolbar's leading edge.
- **leading-toolbar-items-overridable**: The default implementation of
  the leading-toolbar-items hook MUST return an empty list; an extension
  point MAY override it to supply additional leading toolbar views.
- **trailing-toolbar-items-rendered**: The component MUST render every view
  returned by the extra-trailing-toolbar-items hook immediately before the
  built-in Pause button, Clear button, status dot, and status label, all in
  one horizontal stack (8pt spacing, vertically centered) pinned 12pt from
  the toolbar's trailing edge.
- **trailing-toolbar-items-overridable**: The default implementation of
  the extra-trailing-toolbar-items hook MUST return an empty list; an
  extension point MAY override it to insert additional trailing toolbar
  views before the built-ins.
- **lifecycle-start**: The component MUST start the controller each
  time the view appears, which may happen more than once over the
  component's lifetime (hide/show, tab switching, window re-ordering).
  The controller's start operation is documented safe to call repeatedly —
  implementations are expected to tear down any previous stream first — so
  no additional guard against repeated appearances is needed here.
- **lifecycle-stop**: The component MUST stop the controller each
  time the view is about to disappear, which — like the view-appeared
  event — may fire more than once over the component's lifetime.
- **indicator-state-refresh**: The component MUST refresh the
  status dot color, status label text/tooltip, and pause button title
  whenever the controller's state-change notification fires.
- **indicator-theme-refresh**: The component MUST refresh the
  status dot color, status label text/tooltip, and pause button title
  whenever the active theme palette changes.
- **connected-indicator**: When the controller's connected flag is `true`,
  the component MUST fill the status dot with the `.success` role color and
  set the status label's text and tooltip to `Connected`.
- **error-indicator**: When the controller's connected flag is `false` and
  its last-error value is set, the component MUST fill the status dot
  with the `.danger` role color and set the status label's text and tooltip
  to that error value verbatim.
- **connecting-indicator**: When the controller's connected flag is `false`
  and its last-error value is unset, the component MUST fill the status dot
  with the `.warning` role color and set the status label's text and tooltip
  to `Connecting…`.
- **connection-state-in-text**: The component MUST expose the
  connection state to assistive technology through text, not color alone —
  the status label's displayed text and tooltip are both set to the same
  string (`Connected` / `Connecting…` / the error text) that also selects
  the dot's color, so the status dot's color is never the only carrier of
  the state.
- **pause-button-title-tracks-pause-state**: The component MUST set the pause
  button's title to `Resume` when the controller's paused flag is `true`,
  and to `Pause` when it is `false`.
- **pause-action**: Clicking the pause button MUST
  call the controller's toggle-pause operation.
- **clear-action**: Clicking the clear button MUST call the controller's
  clear operation.
- **default-start-size-floor**: The root view's initial frame MUST be sized
  to at least `900×600`, or to `minimumContentSize` where that is larger on
  either dimension.
- **status-dot-fixed-size**: The status dot MUST be sized to a fixed
  `8×8pt`, independent of any theme size scaling.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

