
The Settings Panel Split is the base component for a settings panel that is
itself a nested topic/detail split — a sub-hierarchy (for example, a
"Theme" topic with several sub-panels) hosted in the outer settings
window's own detail pane. It builds on the settings split view (the
split-pane container: sidebar of panels plus a detail pane showing the
current selection) and satisfies the interface that lets a component be
hosted as a settings panel through that same inheritance, so an instance
can be added as a row/panel of an *enclosing* settings split while itself
hosting a second, independent sidebar and detail pane. This is what lets a
sub-hierarchy be expressed as one added panel rather than a second window
or sheet. This recipe documents only what this component itself declares
or overrides; the sidebar/detail mechanics it inherits (panel management,
navigation history, theming, the help drawer plumbing) belong to the
settings split view's own recipe, and the panel-list rendering it composes
belongs to the panel list's own recipe.

