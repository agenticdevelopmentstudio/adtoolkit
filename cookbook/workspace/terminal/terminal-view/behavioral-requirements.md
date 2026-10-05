
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **caret-appearance-property**: The component MUST expose a public
  appearance property (fields: a caret color, a text color, an
  always-hollow flag, a marks-active-pane flag), defaulting to a white
  caret color and white text color with both flags `false` when the
  caller sets no value.
- **appearance-change-recompute**: WHEN the appearance property is set to
  a new value, the component MUST re-evaluate whether the caret is
  hollow and re-apply the caret's color, text color, and border
  accordingly.
- **window-attach-recompute**: WHEN the view is attached (or moved) to a
  window, the component MUST re-evaluate whether the caret is hollow and
  re-apply the caret's color, text color, and border accordingly.
- **active-pane-subscription**: The component MUST subscribe, at
  initialization, to the active-pane tracker's change notification for
  the lifetime of the instance.
- **active-pane-notification-window-filter**: WHEN a change notification
  from the active-pane tracker is received, the component MUST
  re-evaluate and re-apply the caret's appearance only if the
  notification identifies the same window as the view's own window;
  otherwise it MUST take no action.
- **cursor-shown-outline-reapply**: WHEN the terminal engine signals that
  the cursor is now shown, the component MUST re-apply the caret's
  border using its already-computed hollow/filled state, without
  recomputing that state.
- **cursor-style-change-outline-reapply**: WHEN the terminal engine
  signals that its cursor style changed, the component MUST re-apply the
  caret's border using its already-computed hollow/filled state, without
  recomputing that state.
- **always-hollow-flag**: The component MUST treat the caret as hollow
  whenever the always-hollow flag is `true`, regardless of the
  marks-active-pane flag or the active-pane state.
- **active-pane-marking**: WHEN the always-hollow flag is `false` AND the
  marks-active-pane flag is `true`, the component MUST treat the caret
  as hollow if and only if this view is not currently within the pane
  the active-pane tracker considers active.
- **default-fill**: WHEN the always-hollow flag is `false` AND the
  marks-active-pane flag is `false`, the component MUST treat the caret
  as filled, independent of the active-pane state.
- **hollow-caret-color**: WHEN the caret is hollow, the component MUST
  set the inherited caret-color property to fully transparent.
- **filled-caret-color**: WHEN the caret is filled, the component MUST
  set the inherited caret-color property to the appearance's own color.
- **hollow-text-color**: WHEN the caret is hollow, the component MUST set
  the inherited caret-text-color property to the appearance's own text
  color.
- **filled-text-color**: WHEN the caret is filled, the component MUST
  clear the inherited caret-text-color property to its unset/default
  state.
- **hollow-border**: WHEN the caret is hollow AND the terminal engine's
  caret subview can be located, the component MUST set that subview's
  layer border width to `1` point and its border color to the
  appearance's own color.
- **filled-border**: WHEN the caret is filled AND the terminal engine's
  caret subview can be located, the component MUST set that subview's
  layer border width to `0` and clear its border color.
- **missing-caret-subview-tolerance**: WHEN the terminal engine's caret
  subview cannot be located, the component MUST take no action on the
  border and MUST NOT raise an error or crash.
- **caret-subview-type-name-match**: The component MUST locate the
  terminal engine's caret subview by finding the first direct subview
  whose runtime type name ends with the suffix `"CaretView"`.
- **caret-subview-cache**: The component SHOULD cache the located caret
  subview through a weak reference, and SHOULD re-search its subviews
  for a replacement whenever the cached reference's superview is no
  longer the component itself.

