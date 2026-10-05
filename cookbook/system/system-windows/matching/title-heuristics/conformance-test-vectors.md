
Titles below write the em dash as "—" (U+2014) and the en dash as "–"
(U+2013).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wmh-001 | xcode-first-component | The Xcode heuristic given "MyApp — ContentView.swift" | "MyApp" |
| wmh-002 | separator-set, xcode-first-component | The Xcode heuristic given "MyApp – ContentView.swift" | "MyApp" |
| wmh-003 | xcode-no-separator-whole-title | The Xcode heuristic given "MyApp" | "MyApp" |
| wmh-004 | xcode-first-component | The Xcode heuristic given "QualityTime — ContentView.swift (Edited)" | "QualityTime" |
| wmh-005 | xcode-empty-first-component-nil | The Xcode heuristic given "   " (three spaces) | An absent value |
| wmh-006 | empty-title-nil | "" given to each of the five heuristics | An absent value from all five |
| wmh-007 | separator-hyphen-not-split, xcode-no-separator-whole-title | The Xcode heuristic given "MyApp - ContentView.swift" | "MyApp - ContentView.swift" |
| wmh-008 | separator-first-match-wins | The component-splitting operation given "A — B – C" | `["A", "B – C"]` |
| wmh-009 | separator-absent-single-component | The component-splitting operation given "  zsh " | `["zsh"]` |
| wmh-010 | separator-components-trimmed | The component-splitting operation given "a — " | `["a", ""]` |
| wmh-011 | warp-path-last-component, warp-strip-branch | The Warp heuristic given "mike - ~/projects/myapp (develop)" | "myapp" |
| wmh-012 | warp-root-path-nil | The Warp heuristic given "user - / (main)" | An absent value |
| wmh-013 | warp-strip-dirty-indicator, warp-strip-branch | The Warp heuristic given "Claude - QualityTime (main) *" | "QualityTime" |
| wmh-014 | warp-plain-remainder | The Warp heuristic given "mike - Documents" | "Documents" |
| wmh-015 | warp-requires-hyphen-separator | The Warp heuristic given "QualityTime — main" | An absent value |
| wmh-016 | warp-remainder-after-first-separator | The Warp heuristic given "a - b - c" | "b - c" |
| wmh-017 | warp-path-last-component | The Warp heuristic given "mike - ~/projects/myapp/" | "myapp" |
| wmh-018 | brave-strip-suffix | The Brave heuristic given "GitHub - Pull Requests - Brave" | "GitHub - Pull Requests" |
| wmh-019 | brave-bare-app-name-nil | The Brave heuristic given "Brave" | An absent value |
| wmh-020 | brave-strip-suffix | The Brave heuristic given " - Brave" | An absent value |
| wmh-021 | brave-fallback-whole-title, brave-suffix-case-sensitive | The Brave heuristic given "Docs - Brave Browser" | "Docs - Brave Browser" |
| wmh-022 | vscode-default-first | The VS Code heuristic given "temporal — api.go" | "temporal" |
| wmh-023 | vscode-filename-first-prefers-last, vscode-filename-test | The VS Code heuristic given "settings.json — myproject" | "myproject" |
| wmh-024 | vscode-default-first | The VS Code heuristic given "api.go — main.ts" | "api.go" |
| wmh-025 | vscode-single-component, vscode-generic-titles | The VS Code heuristic given "Welcome" | An absent value |
| wmh-026 | vscode-generic-last-returns-first | The VS Code heuristic given "Welcome — Visual Studio Code" | "Welcome" (the heuristic's own documentation says an absent value; see the open question on vscode-welcome-doc-contract) |
| wmh-027 | vscode-default-first | The VS Code heuristic given " — foo" (leading space, empty first component) | An absent value |
| wmh-028 | vscode-filename-test | The VS Code heuristic given "notes.JSON — proj" | "proj" (extension match is case-insensitive) |
| wmh-029 | terminal-second-component, terminal-strip-one-dash | The Terminal heuristic given "mfullerton — -zsh — 80x24" | "zsh" |
| wmh-030 | terminal-second-component | The Terminal heuristic given "mfullerton — ssh user@host" | "ssh user@host" |
| wmh-031 | terminal-strip-one-dash | The Terminal heuristic given "u — --x" | "-x" |
| wmh-032 | terminal-strip-one-dash | The Terminal heuristic given "u — -" | An absent value |
| wmh-033 | terminal-single-component | The Terminal heuristic given "bash" | "bash" |
| wmh-034 | terminal-strategy-app-only, default-fingerprint-pattern | The Terminal heuristic's fingerprint operation given "u — vim — 80x24" | Pattern "vim", strategy app-only |
| wmh-035 | default-strategy-substring, default-fingerprint-pattern | The Xcode heuristic's fingerprint operation given "MyApp — a.swift" | Pattern "MyApp", strategy app-and-title-substring |
| wmh-036 | default-fingerprint-pattern | The Brave heuristic's fingerprint operation given "Brave" | An absent value |
| wmh-037 | xcode-identity, warp-identity, brave-identity, vscode-identity, terminal-identity | Read the name and app-names list of each built-in heuristic | "Xcode"/`["Xcode"]`; "Warp"/`["Warp"]`; "Brave Browser"/`["Brave Browser"]`; "VS Code"/`["Code", "Visual Studio Code", "Cursor"]`; "Terminal"/`["Terminal"]` |
| wmh-038 | heuristic-pure, heuristic-concurrency-safety | The pattern-extraction operation called on one shared heuristic instance from many concurrent tasks with the same title | Every call returns the same value; no data race is reported under strict concurrency checking |

Vectors wmh-001, wmh-002, wmh-011, wmh-012, wmh-022, and a handful of others
noted individually above are asserted by the reference test suite; the rest
are traced to each heuristic's own logic and documented examples.

