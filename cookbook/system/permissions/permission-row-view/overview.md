
The permission row is a self-contained card that renders one permission's
live grant status: an icon, a title, a one-line explanation, a status dot
plus label, and a trailing action button that either opens the platform's
permission settings or, for a permission with no settings pane, triggers the
host app's own consent dialog. It has no dependency on any settings
framework. It is composed by the panel that lists all permissions, which
stacks one row per permission and drives a refresh on appear, on app
reactivation, and after an action completes.

