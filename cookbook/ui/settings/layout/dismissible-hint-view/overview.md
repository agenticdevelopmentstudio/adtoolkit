
The dismissible hint view is a settings row pairing a wrapping hint label
with a small dismiss button. It is a "coachmark-style hint" that hides
itself once its backing setting flips to `true`, intended for one-time
onboarding prompts such as "enable launch at login so you never miss a
session." It self-reports visibility changes so a hosting group view can
collapse the padding and hairline around a card row whose content has
hidden itself, rather than leaving an empty band behind — the same
mechanism the sibling conditional view recipe
(`adtoolkit://cookbook/ui/settings/layout/conditional-view`) uses for
the same reason.

