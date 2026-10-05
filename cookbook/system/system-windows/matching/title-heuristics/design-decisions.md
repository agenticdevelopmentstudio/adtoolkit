
**Decision**: A heuristic returns `nil` rather than an empty string or an error when it cannot extract a pattern.
**Rationale**: `SystemWindowMatcher` treats `nil` as "fall back to the raw title with the substring strategy" (or app-only for an empty title); a single optional result keeps the heuristics pure and leaves the fallback policy in one place.
**Approved**: pending

**Decision**: `HeuristicTitleParser` splits on the en dash as well as the em dash, accepting that content containing " – " gets split.
**Rationale**: The parser's NOTE states em dash is by far the common separator, a few locales/builds use an en dash, and content en-dashes are rare; the behavior is covered by `HeuristicTests` (the Xcode en-dash test).
**Approved**: pending

**Decision**: `TerminalHeuristic` recommends `appOnly` for every title, not only for plain shells.
**Rationale**: The doc comment states plain-shell titles are not distinctive enough and appOnly "is the safest default"; the code applies it unconditionally, so even a distinctive command such as "ssh user@host" is fingerprinted app-only while the extracted command is still stored as the pattern.
**Approved**: pending

**Decision**: `WarpHeuristic` returns `nil` for a root path instead of "/".
**Rationale**: The code comment and the `warpRoot` test state a bare root yields no useful pattern; returning "/" would substring-match every path-bearing Warp title.
**Approved**: pending

**Decision**: `VSCodeHeuristic` prefers the last component only when the first looks like a filename and the last does not, using a fixed list of 27 common extensions.
**Rationale**: VS Code puts the workspace first when one is open but shows "file — workspace" in other layouts; the fixed list avoids treating dotted project names (for example "v1.2") as filenames.
**Approved**: pending

**Decision**: Only `WarpHeuristic` parses an ASCII " - " and has no whole-title fallback; Brave parses the " - Brave" suffix; the rest use `HeuristicTitleParser`.
**Rationale**: Warp and Brave titles use a hyphen, not a dash separator; Warp without " - " is not in its "user - directory" format, so the heuristic declines rather than guessing.
**Approved**: pending

**Decision**: The VS Code heuristic returns "Welcome" for the Welcome title, contradicting its own documentation.
**Rationale**: It stands today because the generic-last branch skips the generic-set check. Closing it needs a decision on whether the code or the documentation is authoritative, and a test for this title in the reference test suite.
**Approved**: pending

