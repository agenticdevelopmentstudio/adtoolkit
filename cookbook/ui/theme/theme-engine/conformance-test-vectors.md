
Vectors derived from `SyntaxRoleOverridesTests.swift`,
`VSCodeThemeImporterTests.swift`, `LegacyThemePersistenceTests.swift` and
`ExternalThemeChangeObservationTests.swift` are marked (test). "Minimal theme"
means a document with `editor.foreground` `#D8DEE9`, `editor.background`
`#2E3440`, `editorCursor.foreground` `#FF00FF`, `editor.selectionBackground`
`#4C566A` and all sixteen ANSI keys.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-engine-001 | syntax-role-vocabulary | The full set of syntax roles | 10 roles, named `keywords` … `comments`, in declaration order |
| theme-engine-002 | syntax-style-defaults, syntax-style-shape | Construct a syntax style from a color alone | bold is false, italic is false |
| theme-engine-003 | override-key-spelling (test) | Compute the override key for the `keywords` role with no flags, bold only, italic only, and both flags | `syntax.keywords`, `syntax.keywords.bold`, `syntax.keywords.italic`, `syntax.keywords.bold.italic`, respectively |
| theme-engine-004 | syntax-styles-read, override-key-spelling (test) | For every role × flag combination, a theme whose only override key is that role/flag combination's computed key, mapped to color c | Reading syntax styles returns exactly that role mapped to a style of color c with the matching bold/italic flags |
| theme-engine-005 | override-key-flag-order (test) | Override map holds `syntax.comments.italic.bold` → c | Reading syntax styles returns `comments` mapped to a style of color c, bold and italic both set |
| theme-engine-006 | override-key-prefix, override-key-role, override-key-flag-vocabulary, override-key-flag-once, override-key-no-throw (test) | Each of `syntax.nope`, `syntax.keywords.underline`, `syntax.keywords.bold.bold`, `syntax`, `syntax.`, `keywords`, `syntaxkeywords`, `prefix.syntax.keywords` → c1, alone and beside `syntax.strings` → c2 | Alone: reading syntax styles is empty. Beside: reading syntax styles returns only `strings` mapped to color c2 |
| theme-engine-007 | syntax-styles-empty | Theme with an override map of `["accent": c]` | Reading syntax styles is empty |
| theme-engine-008 | syntax-styles-tiebreak (test) | `syntax.keywords` → c1, `syntax.keywords.bold` → c2, `syntax.keywords.italic` → c3, in every insertion order | Reading syntax styles always returns `keywords` mapped to a style of color c3, italic set |
| theme-engine-009 | syntax-styles-invisible-to-roles (test) | Theme whose override map is one syntax key per role (10 keys) | The semantic palette reports every semantic role as undeclared, and each role's color equals its derived (non-override) color |
| theme-engine-010 | syntax-styles-travel (test) | Theme carrying all four key shapes plus an `accent` override, serialized then deserialized | Its override map and syntax styles equal the original's; only `accent` is a declared semantic role |
| theme-engine-011 | with-syntax-styles-replace, with-syntax-styles-preserve, with-syntax-styles-write (test) | Overrides `syntax.keywords.bold` → c1, `syntax.keywords.underline` → c8, `accent` → c9; replace syntax styles with `keywords` mapped to a style of color c2 | `syntax.*` keys are exactly `syntax.keywords`, `syntax.keywords.underline`; the rejected underline key is still c8; reading syntax styles returns `keywords` mapped to color c2; `accent` is still c9 |
| theme-engine-012 | with-syntax-styles-clear (test) | Syntax keys plus `accent` → c9; replace syntax styles with an empty set | Reading syntax styles is empty; the override map holds only `accent` → c9 |
| theme-engine-013 | with-syntax-styles-copy | Replace syntax styles on a copy of a theme (`comments` mapped to style s) | The original theme's override map is unchanged |
| theme-engine-014 | import-bytes-entry, import-name-from-label, import-lock-flags, import-appearance (test) | Parse the minimal theme from bytes with label `"Acme Dark"` and uiTheme `"vs-dark"` | Name is `"Acme Dark"`, appearance is dark, not built-in, not already marked imported, foreground `#D8DEE9FF`, background `#2E3440FF`, cursor `#FF00FFFF`, selection `#4C566AFF`, 16 ANSI colours, valid palette |
| theme-engine-015 | import-ansi-order (test) | Minimal theme whose ANSI slot n is `#0n0000` | ANSI slot 0 is `#000000FF`, slot 5 is `#050000FF`, slot 15 is `#0F0000FF` |
| theme-engine-016 | import-jsonc (test) | Minimal theme with comments and trailing commas vs its strict-JSON spelling | Identical palette, name, appearance and override map |
| theme-engine-017 | import-encodings (test) | Minimal theme as UTF-16, as UTF-16 JSONC, and as UTF-8 with BOM | Each parses to the UTF-8 result |
| theme-engine-018 | import-bytes-ignores-include (test) | Minimal theme plus `"include": "./base.json"`, parsed from bytes | Same palette as without the key; no failure |
| theme-engine-019 | import-root-object (test) | Bytes `[1, 2, 3]` | Fails with a not-an-object error |
| theme-engine-020 | import-syntax-error-passthrough | Bytes `{ "colors": ` (truncated) | Fails with the underlying JSON-parsing error, not an import-specific error |
| theme-engine-021 | import-colors-object (test) | `colors` missing, `null`, or `"x"` | Fails with a missing-colors error |
| theme-engine-022 | import-foreground-required, import-background-required, hex-invalid-absent (test) | `editor.foreground` missing; then `editor.background` missing; then `editor.foreground` `"red"` | Missing-color error naming `editor.foreground`; missing-color error naming `editor.background`; missing-color error naming `editor.foreground` |
| theme-engine-023 | import-validation-order | Both `editor.foreground` and `editor.background` missing | Fails with a missing-color error naming `editor.foreground` |
| theme-engine-024 | import-ansi-complete (test) | Minimal theme minus `terminal.ansiGreen`; then minus several keys | Missing-ANSI-colors error naming `terminal.ansiGreen`; then naming every missing key, in slot order |
| theme-engine-025 | import-foreground-background-distinct (test) | Foreground and background both `#2E3440` | Fails with a foreground-matches-background error |
| theme-engine-026 | import-appearance, import-appearance-fallback (test) | Minimal theme (dark background) with `uiTheme` `vs`, `hc-light`, `vs-dark`, `hc-black`, `aurora`; then background `#FFFFFF` with `aurora` | light, light, dark, dark, dark, respectively; then light |
| theme-engine-027 | import-cursor (test) | Minimal theme without `editorCursor.foreground` | Cursor color equals the foreground color |
| theme-engine-028 | import-selection-opaque (test) | Background `#011627`, `editor.selectionBackground` `#3392FF44` | Selection color equals `#3392FF44` composited over `#011627FF`; the stored value's alpha byte is `FF` |
| theme-engine-029 | import-selection-source, import-selection-fallback (test) | Only `editor.inactiveSelectionBackground` `#1D3B53`; then neither selection key | Selection color is `#1D3B53FF`; then selection is the background blended 20% toward the foreground |
| theme-engine-030 | import-role-overrides, import-role-overrides-present-only (test) | All six mapped keys present | Override map has exactly 6 entries, each at its mapped semantic role, each reported as declared |
| theme-engine-031 | import-no-other-roles (test) | `textLink.foreground`, `errorForeground`, `contrastBorder`, `editorWarning.foreground` present, no mapped key | Override map is empty; `accent`, `danger`, `border`, `warning`, `windowBackground`, `primaryText`, `selection` are all reported undeclared |
| theme-engine-032 | hex-forms (test) | fg `#ABCDEF12`, bg `123456`, cursor `#F0A`, `focusBorder` `#1234`, `input.background` `ABCDEF` | `#ABCDEF12`, `#123456FF`, `#FF00AAFF`, outline `#11223344`, controlBackground `#ABCDEFFF` |
| theme-engine-033 | hex-invalid-absent (test) | `editorCursor.foreground` `null`, a mapped role key as an array or a number | Cursor equals foreground; override map empty; no failure |
| theme-engine-034 | token-scope-forms (test) | Same rules as `scope: ["a", "b"]` and as `scope: "a, b"` | Identical syntax styles |
| theme-engine-035 | token-specificity (test) | Rules `keyword` → `#111111` and `keyword.control` → `#222222`, in both orders | `keywords` colour `#222222FF` both times |
| theme-engine-036 | token-tiebreak (test) | Two `keyword.control` rules, `#111111` then `#222222` bold | `keywords` = `#222222FF` + bold |
| theme-engine-037 | token-selector-clean (test) | `meta.tag entity.name.function` → c1 and `entity.name` → `#111111`; then the descendant rule alone | `commands` = `#111111FF`; then no `commands` style |
| theme-engine-038 | token-selector-clean (test) | `scope: "meta.tag entity.name.function, constant.numeric"` → `#333333` | `numbers` = `#333333FF`; no `commands` style |
| theme-engine-039 | token-emphasis (test) | `fontStyle` `italic`, `bold italic`, `italic bold`, `bold`, `underline`, `normal`, `regular`, `bold underline`, empty, absent on `#C792EA` | `+italic`, `+bold+italic`, `+bold+italic`, `+bold`, plain, plain, plain, `+bold`, plain, plain |
| theme-engine-040 | token-scope-chain, token-chain-first-match (test) | Only `support.type` → `#FFCB8B`; then `entity.name.type` → `#ADDB67` and `support.type` → `#FFCB8B` | `types` = `#FFCB8BFF`; then `#ADDB67FF` |
| theme-engine-041 | token-chain-first-match | Rules `entity` → c1 and `support.type` → c2 | `types` = c1 |
| theme-engine-042 | token-rule-usable, hex-shared (test) | `keyword.control` with foreground `"nope"`, with only `fontStyle`, with foreground `42`, each beside `keyword` → `#111111`; then foreground `#ABC` on `string.quoted.double` | `keywords` = `#111111FF` each time; `strings` = `#AABBCCFF` |
| theme-engine-043 | token-rules-source, token-no-throw, token-unmatched-role (test) | `tokenColors` absent, `"keyword.control"`, `{ "scope": "keyword" }`, `null`, `[]` | No failure; syntax styles empty; palette identical to the minimal theme |
| theme-engine-044 | token-stored-as-overrides (test) | Minimal theme with a `comment.line` rule vs without | Palette identical; non-`syntax.` overrides identical; syntax styles' keys are exactly `[comments]` |
| theme-engine-045 | import-file-entry, include-merge-colors (test) | `variant.json` `{"include": "./base.json", "colors": {"editor.background": "#111111"}}`; `base.json` is the minimal theme | foreground `#D8DEE9FF`, background `#111111FF`, cursor `#FF00FFFF`, 16 ANSI |
| theme-engine-046 | include-merge-tokens (test) | Base and variant each with a `comment.line` rule; variant also `keyword.control` → `#222222` | `comments` from the variant (`#333333FF`); `keywords` `#222222FF` |
| theme-engine-047 | include-cycle, include-depth-bound (test) | `a.json` includes `./b.json`, `b.json` includes `./a.json` | Fails with an include-chain-too-deep error (limit 8) |
| theme-engine-048 | include-containment, import-file-default-root (test) | `themes/variant.json` includes `../outside/secret.json`, no containment root given | Fails with an escapes-containment-root error |
| theme-engine-049 | include-resolve (test) | Same files, containment root set to the parent directory | Parses; foreground `#D8DEE9FF` |
| theme-engine-050 | include-detect, import-file-entry (test) | Minimal theme on disk with no `include` | Same palette as parsing the same bytes directly |
| theme-engine-051 | include-merge-other, include-consumed | Base `{"x": 1, ...}`, variant `{"include": "./base.json", "x": 2}` | Merged document has `x == 2` and no `include` key |
| theme-engine-052 | import-file-errors | Parse a file at a path that does not exist | Fails with the file-read error; nothing parsed |
| theme-engine-053 | store-import, store-import-locked (test) | A theme store over in-memory storage; import the minimal theme file with label `"Acme Dark"` and uiTheme `"vs-dark"` | Returned theme's name is `"Acme Dark"`, marked imported, locked, not editable; the custom-themes list holds exactly its id; the full theme catalog contains it |
| theme-engine-054 | store-import-failure | Import a file whose `colors` is missing | Fails with a missing-colors error; the custom-themes list is unchanged |
| theme-engine-055 | store-import-no-rename | Import the same file twice with the same label | Two custom themes, both named the label, with different ids |
| theme-engine-056 | storage-active-key, storage-legacy-compatible (test) | The settings store already holds `theme.active_theme_id` = the Dracula theme's id, written the pre-seam way | A freshly constructed settings-backed storage's active-theme-id reads back the Dracula theme's id |
| theme-engine-057 | storage-legacy-compatible (test) | Set the storage's active-theme-id to the Nord theme's id | The settings store's `theme.active_theme_id` key holds the Nord theme's id |
| theme-engine-058 | storage-nil-write, storage-read-non-nil | Clear the storage's active-theme-id, then read it back | Reads the built-in catalog's default theme id |
| theme-engine-059 | storage-custom-themes-key | Set the storage's custom-themes list to `[t]`, then read the settings store's custom-themes setting directly | `[t]` |
| theme-engine-060 | storage-change-any-writer, storage-change-deferred (test) | A theme manager over this storage; write the settings store's active-theme-id setting directly to the Dracula theme's id | After the main work queue drains, a change notification fires and the manager's current theme is the Dracula theme |
| theme-engine-061 | storage-change-any-writer (test) | Rewrite the settings store's custom-themes setting with the active custom theme renamed | Notification fires; the manager's current theme has the new name |
| theme-engine-062 | storage-change-any-writer (test) | Select the Dracula theme through the manager | Exactly one change notification fires (the storage callback fires, but the manager's reload de-duplicates) |
| theme-engine-063 | storage-observers-lazy, storage-change-no-initial | Set the external-change callback to a counter, drain the main work queue, then clear the callback and write both settings | Counter stays 0 |
| theme-engine-064 | store-default-init, manager-default-init, manager-default-reads-disk (test) | The settings store already holds `theme.active_theme_id` = the Gruvbox Dark theme's id; construct a default theme manager | Current theme is Gruvbox Dark |

