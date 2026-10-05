
### Shared contract

- **heuristic-shape**: Every heuristic MUST expose a name (a user-visible display name), an app-names list (the owning-app names it applies to), a pattern-extraction operation taking a raw title and returning an optional string, a recommended-strategy value, and a fingerprint operation returning an optional pattern-and-strategy pair.
- **heuristic-concurrency-safety**: Every heuristic MUST be safe to share and call across concurrent isolation contexts; the heuristic contract requires this, and each built-in is an immutable value type whose only stored properties are constants.
- **heuristic-pure**: The pattern-extraction operation MUST return the same result for the same title on every call, with no side effects (no I/O, no logging, no stored state), so it MAY be called from any thread or task concurrently.
- **nil-means-no-pattern**: The pattern-extraction operation MUST return an absent value, never an empty string, when it cannot extract a useful pattern; no built-in throws or reports an error.
- **empty-title-nil**: Every built-in heuristic MUST return an absent value for the empty title `""`.
- **default-strategy-substring**: A heuristic that does not override its recommended strategy MUST report the app-and-title-substring strategy; the Xcode, Warp, Brave and VS Code heuristics use this default.
- **default-fingerprint-pattern**: The default fingerprint operation MUST return an absent value when the pattern-extraction operation returns an absent value, and otherwise MUST return the extracted pattern paired with the recommended strategy; none of the five built-ins overrides it.
- **trim-spaces-and-tabs-only**: Every trim a heuristic performs MUST strip only horizontal whitespace (spaces and tabs); newlines inside a title are preserved.
- **pattern-case-preserved**: A heuristic MUST return the extracted text with its original letter case; case folding is left to the matcher.

### Title separator parsing

- **separator-set**: The title-parser's separator list MUST be, in order, space + em dash (U+2014) + space, then space + en dash (U+2013) + space.
- **separator-first-match-wins**: The component-splitting operation MUST split the title on every occurrence of the first separator in that list that the title contains, and MUST NOT additionally split on the other separator.
- **separator-components-trimmed**: The component-splitting operation MUST trim spaces and tabs from each resulting component, keeping empty components in place.
- **separator-absent-single-component**: When the title contains neither separator, the component-splitting operation MUST return a one-element list holding the trimmed title; it never returns an empty list.
- **separator-hyphen-not-split**: The component-splitting operation MUST NOT treat an ASCII hyphen surrounded by spaces (" - ") as a separator.

### Xcode heuristic

- **xcode-identity**: The Xcode heuristic MUST have the name "Xcode" and an app-names list of exactly `["Xcode"]`.
- **xcode-first-component**: The Xcode heuristic MUST return the first title-parser component of the title (the project name before the em or en dash).
- **xcode-no-separator-whole-title**: With no dash separator, the Xcode heuristic MUST return the whole trimmed title (for example an organizer window titled "MyApp").
- **xcode-empty-first-component-nil**: The Xcode heuristic MUST return an absent value when the first component is empty after trimming.

### Warp heuristic

- **warp-identity**: The Warp heuristic MUST have the name "Warp" and an app-names list of exactly `["Warp"]`.
- **warp-requires-hyphen-separator**: The Warp heuristic MUST return an absent value when the title does not contain " - " (space, ASCII hyphen, space); unlike the other heuristics it has no whole-title fallback and does not use the title-parser helper.
- **warp-remainder-after-first-separator**: The Warp heuristic MUST take everything after the first " - " occurrence, trimmed, as the remainder; later " - " occurrences stay inside the remainder.
- **warp-strip-dirty-indicator**: When the remainder ends with " *" (space, asterisk), the Warp heuristic MUST remove those two characters.
- **warp-strip-branch**: After the dirty indicator is handled, the Warp heuristic MUST cut the remainder at its first " (" (space, open parenthesis), discarding that and everything after it, then trim.
- **warp-path-last-component**: When the remaining text contains "/", the Warp heuristic MUST return its last non-empty "/"-separated component, trimmed.
- **warp-root-path-nil**: When the remaining text contains "/" but has no non-empty "/"-separated component (for example "/"), the Warp heuristic MUST return an absent value, not a literal slash.
- **warp-plain-remainder**: When the remaining text has no "/", the Warp heuristic MUST return it, or an absent value when it is empty.

### Brave heuristic

- **brave-identity**: The Brave heuristic MUST have the name "Brave Browser" and an app-names list of exactly `["Brave Browser"]`.
- **brave-strip-suffix**: When the title ends with " - Brave", the Brave heuristic MUST return the text before that suffix, trimmed, or an absent value when that text is empty.
- **brave-bare-app-name-nil**: When the trimmed title equals "Brave" exactly, the Brave heuristic MUST return an absent value.
- **brave-fallback-whole-title**: Any other non-empty title MUST produce the whole trimmed title, or an absent value when trimming leaves it empty.
- **brave-suffix-case-sensitive**: The " - Brave" suffix and the bare "Brave" comparison MUST be case-sensitive exact matches; " - brave" and " - Brave Browser" do not strip.

### VS Code heuristic

- **vscode-identity**: The VS Code heuristic MUST have the name "VS Code" and an app-names list of exactly `["Code", "Visual Studio Code", "Cursor"]`.
- **vscode-generic-titles**: The VS Code heuristic MUST treat exactly "Visual Studio Code", "Welcome", "Get Started" and "Settings" as generic titles, compared case-sensitively.
- **vscode-single-component**: With no dash separator, the VS Code heuristic MUST return an absent value when the trimmed title is a generic title, and otherwise MUST return the trimmed title (an absent value when empty).
- **vscode-generic-last-returns-first**: With two or more components, when the last component is a generic title, the VS Code heuristic MUST return the first component (an absent value when empty), even when that first component is itself generic.
- **vscode-filename-first-prefers-last**: With two or more components, when the last component is not generic, the first looks like a filename and the last does not, the VS Code heuristic MUST return the last component (an absent value when empty).
- **vscode-default-first**: In every other multi-component case, the VS Code heuristic MUST return the first component (an absent value when empty).
- **vscode-filename-test**: A string MUST count as a filename when splitting it on "." (dropping empty pieces) yields at least two pieces and the last piece, lowercased, is one of: swift, ts, tsx, js, jsx, go, py, rs, rb, java, kt, c, cpp, h, hpp, cs, json, yaml, yml, toml, md, txt, html, css, scss, vue, svelte.
- **vscode-welcome-doc-contract**: The VS Code heuristic's documentation declares that "Welcome — Visual Studio Code" yields an absent value ("not a project window"), but the pattern-extraction operation returns "Welcome" for that title because the generic-last branch returns the first component without checking it against the generic set. The code behavior is the current contract.

### Terminal heuristic

- **terminal-identity**: The Terminal heuristic MUST have the name "Terminal" and an app-names list of exactly `["Terminal"]`.
- **terminal-strategy-app-only**: The Terminal heuristic's recommended strategy MUST be the app-only strategy for every title, because plain shell titles are not distinctive; its fingerprints therefore store the extracted pattern with the app-only strategy.
- **terminal-second-component**: With two or more title-parser components, the Terminal heuristic MUST return the second component (the process or command).
- **terminal-strip-one-dash**: When that second component starts with "-", the Terminal heuristic MUST drop exactly one leading "-" (the login-shell marker, "-zsh" to "zsh"), and MUST return an absent value when nothing remains.
- **terminal-empty-second-nil**: The Terminal heuristic MUST return an absent value when the second component is empty.
- **terminal-single-component**: With no dash separator, the Terminal heuristic MUST return the whole trimmed title, or an absent value when it is empty.

