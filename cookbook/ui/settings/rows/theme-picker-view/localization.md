
The component contains no user-facing string literal of its own — it
passes no title argument to the theme-choice view model at all, so it has
no call site of its own to localize. But the choice control's title it
composes is not inert: the theme-choice view model's own default title
("Theme") is a plain string, not routed through a localization mechanism,
and because the component supplies no title of its own, every instance
shows that unlocalized "Theme" default; no localization key exists for the
control's title, and the theme-choice view model has no recipe of its own
to record the gap against. Every other visible string (choice labels,
preview sample text) is owned by its own respective concept.

