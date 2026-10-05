
The Text Edit View is a settings row: a leading label paired with a trailing
plain text field, bound to a string-valued view model. It builds its text
field through an overridable construction point so a variant can substitute
a different control type while inheriting everything else — the row layout,
the theme-driven font/color styling, the edit-completion commit path, and
the view-model sync. The Secure Text Edit View (documented separately at
`adtoolkit://cookbook/ui/settings/rows/secure-text-edit-view`) is the
one variant that exists today, overriding only that construction point to
return a secure text-entry control. This recipe documents the Text Edit View
itself: the behavior every row built from it — plain or secure — inherits.

