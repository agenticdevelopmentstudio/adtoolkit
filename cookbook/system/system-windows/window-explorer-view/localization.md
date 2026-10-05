
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `Windows` | Windows | Header title |
| `Refresh window list` | Refresh window list | Tooltip on the refresh button |
| `Scanning windows...` | Scanning windows... | Loading-state caption |
| `No windows found` | No windows found | Empty-state title |
| `Make sure Accessibility permission is granted.` | Make sure Accessibility permission is granted. | Empty-state hint |
| `Accessibility permission needed for window titles.` | Accessibility permission needed for window titles. | Accessibility banner text |
| `Open Settings` | Open Settings | Accessibility banner action button |
| `(untitled)` | (untitled) | Fallback for a window with an empty title — not localized (see below) |

Every string above is a literal passed to a text, button, or tooltip
control, each of which takes a localization key — per this cookbook's
localization convention, a literal there is itself the localization key,
so these are localizable as written. Values built from runtime data — the
app name, a window's title, a context's name, the window count, and the
dimensions string — are plain string values or string interpolations, not
localization keys, and correctly are not translated as UI strings since
they echo system or user data.

The `(untitled)` fallback is the exception among the literals: when the
title is empty, the view substitutes the literal string `"(untitled)"`
directly rather than through a localization key — as built, this behavior
is defined: the fallback always renders in English regardless of the
user's locale, and the source contains no branch that would localize it
instead.

