
The heuristics produce no user-facing messages. Each heuristic's name is a
hardcoded English (or product-name) literal documented as "the user-visible
name for this heuristic", with no localization lookup:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (literal, Xcode heuristic's name) | Xcode | Heuristic display name |
| (literal, Warp heuristic's name) | Warp | Heuristic display name |
| (literal, Brave heuristic's name) | Brave Browser | Heuristic display name |
| (literal, VS Code heuristic's name) | VS Code | Heuristic display name |
| (literal, Terminal heuristic's name) | Terminal | Heuristic display name |

The parsing literals (" - Brave", the VS Code generic titles "Visual Studio
Code", "Welcome", "Get Started", "Settings") match English application
titles only; a localized VS Code or Brave title is not recognized and falls
through to the default branch.

