
- **initializer-parameters**: Component MUST accept a view model as a
  required construction parameter, plus a visible-line count defaulting to
  `6` and a monospaced flag defaulting to `false` when the caller omits them.
- **row-label-text**: Component MUST display the view model's title as the
  row's label text, built via the shared row-label helper.
- **editor-font-role**: Component MUST render the editor's text in the
  active theme's code-role font when monospaced is `true`, or its body-role
  font when monospaced is `false`, both immediately at construction and
  again on every subsequent theme change.
- **initial-editor-text**: Component MUST display the view model's current
  value as the editor's text content at construction.
- **editor-theme-colors**: Component MUST render the editor's text,
  background, insertion-point (caret), and selection-highlight colors from
  the active theme's primary-text, control-background, cursor, and
  selection/selection-text roles respectively, immediately at construction
  and again on every theme change.
- **plain-text-mode**: Component MUST treat typed content as plain text: no
  rich-text formatting (bold, color, embedded attachments) is applied or
  preserved.
- **undo-support**: Component MUST support standard undo/redo of typed
  edits.
- **automatic-substitution-suppression**: Component MUST NOT apply automatic
  quote, dash, or text-replacement substitutions to typed text, so prose
  intended to be sent elsewhere verbatim is not silently rewritten before it
  leaves the editor.
- **vertical-growth**: Component MUST let the editor's content grow
  vertically without limit as text is typed, and MUST NOT grow horizontally
  with content — its width instead automatically follows its enclosing
  scrolling container.
- **text-wrapping**: Component MUST wrap text to the available width rather
  than scrolling horizontally.
- **text-container-inset**: Component MUST inset the typed text 4pt from the
  editor's edges on every side.
- **scrolling-container**: Component MUST host the editor inside a container
  that scrolls vertically, with a visible vertical scroll indicator and a
  bezeled border, so text beyond the visible height scrolls instead of
  growing the row without bound.
- **scroll-view-theme-background**: Component MUST draw the scrolling
  container's background using the active theme's control-background color,
  immediately at construction and again on every theme change.
- **label-scroll-view-layout**: Component MUST arrange the label above the
  scrolling container in a vertical, leading-aligned layout with the row's
  standard spacing (8pt) between them, and MUST pin that layout to all four
  edges of the component with no additional inset.
- **visible-height**: Component MUST fix the scrolling container's width to
  match the surrounding layout's width, and its visible height to a value
  computed from the active font's line height times the visible-line count,
  so exactly that many lines are visible before scrolling begins.
- **superview-width-claim**: Component MUST, once placed within a host view,
  claim that host's full width as a low-priority preference, so the editor
  is never narrower than its host without conflicting with a host that
  constrains it more strongly.
- **label-resync**: Component MUST, whenever the view model's change
  notification fires, set the label's text to the view model's title.
- **self-inflicted-onchange-guard**: Component MUST NOT overwrite the
  editor's text when the view model's change notification fires while an
  internal commit is in progress, and MUST NOT overwrite it when the
  editor's text already equals the incoming value.
- **external-value-adoption**: Component MUST, on a change notification that
  is not self-inflicted (per self-inflicted-onchange-guard), set the
  editor's text to the new value.
- **caret-position-on-external-change**: Component MUST, when adopting an
  external value change (per external-value-adoption) while the editor has
  focus, move the caret to the end of the new text.
- **accessibility-label**: Component MUST label the editor with the view
  model's title at construction, so a screen reader announces the editor by
  the row's title instead of as an unnamed text area.
- **end-editing-commit**: Component MUST commit (write the editor's text
  toward the view model's committed value, per redundant-commit-guard) when
  editing ends.
- **window-detachment-commit**: Component MUST commit when the component is
  about to be detached from its window.
- **teardown-notification-observers**: Component MUST, whenever the
  component is attached to a window, register to be notified when that
  window closes or the host application terminates, committing in either
  case.
- **stale-observer-deregistration**: Component MUST remove any previously
  registered window-close and application-termination notifications on
  itself every time the component is about to move to a window — including
  detachment — before registering new ones.
- **redundant-commit-guard**: Component MUST NOT write to the view model's
  committed value when the editor's text already equals it.
- **commit-echo-guard**: Component MUST mark a commit as in progress for the
  duration of writing the view model's committed value, and clear that
  marker immediately after, so the resulting change notification is
  recognized as self-inflicted (per self-inflicted-onchange-guard).
- **constituent-view-exposure**: Component MUST expose its label and its
  editor as accessible sub-components, so a caller may inspect or extend
  them directly.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

