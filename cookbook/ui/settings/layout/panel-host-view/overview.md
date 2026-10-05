
The Panel Host View is the detail pane's chrome inside a settings split
view: a plain container view that hosts whichever panel is currently
selected, plus a help button pinned to the panel's top-right corner. Per
the source's own doc comment, one instance lives for the whole life of the
split and only its content is swapped — the button is a property of the
split's chrome, not of any one panel, so it never flickers or moves as the
selection changes. Help itself is disclosed elsewhere: this view forwards
to a help-presenting role (a window drawer or a sheet's popover, depending
on how the owning window is presented) rather than rendering help content
itself. The owning split view controller owns one Panel Host View for its
detail pane and forwards its own help-presenter/shows-help-button/
toggle-help/is-help-visible surface directly to it; the settings window
assigns a presenter only to its root split, which is what keeps a nested
split (a panel that is itself a split view) from showing a second help
button or opening a second drawer.

