
This is the field a user clicks into and then presses the keys they want
recorded as a key command. It looks like a text field but is deliberately
not one: a field editor would eat the very chords being recorded, and a
standard text field's own key handling turns a primary-modifier chord into
an edit command. So this component is a plain focusable view that paints
its own bezel and reads key events directly, intercepting them through the
platform's pre-dispatch key-handling path (so a primary-modifier chord,
which the platform offers to a menu item or the window before ordinary key
handling, is not claimed there first) as well as through its regular
key-handling path (for everything else). It records and reports captured
chords, a bare-Escape cancel, and a bare-Return/Enter commit through
callbacks; it never persists anything itself. Committing a captured chord
is the hosting row's business (a Key Command Row View is the intended
caller) because a captured chord is *pending* until the user says
otherwise, and this component's own loss of focus must not silently decide
that either way.

