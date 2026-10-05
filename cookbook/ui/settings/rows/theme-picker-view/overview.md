
The Theme Picker View is a settings row that stacks a theme-choice control
(bound to a theme-choice view model) above a theme preview. Per its own
description, it is a compact, reusable "theme chooser + live sample" for
dropping into any settings panel that wants a quick theme switch without the
full theme editor. The choice control lists every theme (built-ins plus
custom) and, on selection, writes the chosen theme's id directly to the
shared active-theme setting. The preview is never told about that write
directly; it is driven independently by a palette-observing subscription,
which re-renders it from the current semantic palette immediately at
construction and again every time the theme manager posts its theme-change
notification or the view's own theme scope changes.

