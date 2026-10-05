
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — | "Close Tab" | A tab button's close icon's accessibility description |

"Close Tab" is a hardcoded English literal set directly as an accessibility
description, not routed through any localization mechanism used in this
concept — it is the one non-data-driven, user/assistive-technology-facing
string this component itself owns (a tab's own title text is always supplied
by the caller, so it carries no localization concern of this component's
making).

