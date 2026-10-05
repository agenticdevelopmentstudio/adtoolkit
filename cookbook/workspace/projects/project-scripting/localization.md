
Not applicable: this surface and the three wrapper types produce no
literal user-facing English string of their own. Every fallback value (the
empty string, `false`, `"no"`) is an absence marker for a missing window,
selection, or branch, not translatable text; the strings these wrappers
surface (a project's display name, a tab's title, a pane's selection
description) are already-localized (or user-authored) data owned by other
components.

