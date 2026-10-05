
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (hardcoded literal, no key) | Help | Help button's accessibility label, set once at construction |
| — (hardcoded literal, no key) | Help | Accessible description carried by both help-button icon variants |
| — (hardcoded literal, no key) | Show Help | Help button's tooltip while help is not visible |
| — (hardcoded literal, no key) | Hide Help | Help button's tooltip while help is visible |

All four strings above are set as plain string literals through the
platform's accessibility APIs (see Platform Notes), not through a
dedicated localizable-text position — a literal set this way is not
automatically localizable the way a framework's dedicated localized-text
mechanism is. No localization-catalog lookup appears anywhere in the
source.

