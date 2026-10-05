
The Explanation View is a settings-layout row: a single label showing the
small descriptive blurb rendered beneath a setting. Unlike a single-line,
clipped caption label, it explicitly reconfigures its label to wrap across
as many lines as the caller's text needs and to yield horizontal space
rather than force its container wider — the two properties a blurb needs
that a toolbar caption does not. It is used throughout the app as a
settings-panel help/status line (e.g. help topic bodies, extension
descriptions, key-command captions, plugin failure messages) and, via the
Panel Heading View, as a panel's own caption: that view's caption is an
Explanation View rather than a label of its own, so it wraps inside the
panel by the one policy every settings blurb shares instead of a copy of it.

