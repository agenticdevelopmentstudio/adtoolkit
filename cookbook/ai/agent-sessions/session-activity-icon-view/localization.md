
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — (hardcoded literal, no key) | `Working` | Accessibility label and tooltip when `activity == .working` and `isSummarizing == false` |
| — (hardcoded literal, no key) | `Idle` | Accessibility label and tooltip when `activity == .idle` and `isSummarizing == false` |
| — (hardcoded literal, no key) | `Waiting for you` | Accessibility label and tooltip when `activity == .waiting` and `isSummarizing == false` |
| — (hardcoded literal, no key) | `Summarizing` | Accessibility label and tooltip when `isSummarizing == true`, regardless of `activity` |

These four strings are assigned as plain text values, not through any
localization-aware string type — so, unlike a string handed to a declarative
UI framework's text/label controls, which some frameworks localize
automatically from a string catalog, none of these four are localized by the
platform automatically; each needs an explicit lookup (e.g. a string-catalog
or resource-bundle entry) to translate.

The source performs no such lookup, so all four reach assistive technology
and the tooltip in English only.

