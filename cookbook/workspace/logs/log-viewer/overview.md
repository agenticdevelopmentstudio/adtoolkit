
This component pairs a log view with a toolbar strip carrying the controls
a streaming log needs: a Pause button, a Clear button, and a
connection-status indicator (a colored dot plus a text label). It hosts any
log controller, so the source of rows (SSE, file tail, test fixture) is
swappable without changing the component. A subclass or extension point
splices in domain-specific toolbar items via a leading-toolbar-items hook
and an extra-trailing-toolbar-items hook, and can override the minimum
content size and the toolbar height. The log view itself — the scrolling
table of log rows — is a separate component with its own concerns (columns,
row click dispatch, tail-follow scrolling); this recipe covers only what
this component itself renders, lays out, and wires around that hosted view.

