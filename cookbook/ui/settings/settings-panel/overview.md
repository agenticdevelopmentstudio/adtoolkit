
The Settings Panel is the base type every settings panel is built from. One
instance is hosted in the right-hand detail pane of a settings split view,
and the sidebar's list-item metadata lives on the panel itself, via its
descriptor — "the panel *is* the list item — no wrapper struct." Its content
view is a panel view instance this type owns and constructs, exposed as its
own view. It conforms to a settings-panel role, redeclaring that role's
help-content, effective-help-content, hosts-own-scroll, and search-keywords
defaults directly on the type (rather than inheriting them from a shared
default) so that a subclass override is actually reached through the
generic reference the hosting split holds. It also exposes a convenience
method for adding a group, forwarding to its own content view, and a helper
that lets a subclass host differently-sized UI content as its own view
without that content's intrinsic size resizing the settings window it sits
in.

