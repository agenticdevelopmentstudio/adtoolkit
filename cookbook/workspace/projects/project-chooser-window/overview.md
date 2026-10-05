
The project chooser window is the app-modal "which project?" dialog: it
hosts a private content view that in turn hosts a project browser in
chooser mode behind a Cancel/Open button pair. It resolves to at most one
repository record drawn from a coordinating component's list of
repositories, reached through a single choose-and-callback entry point that
a menu command calls. Per its own design rationale it is deliberately
app-modal rather than a sheet: "this app has no window guaranteed to be on
screen when the question is asked (it can be asked from the menu bar with
nothing open at all), and a sheet with no parent cannot be dismissed".

