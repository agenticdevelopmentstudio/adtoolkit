
### Syntax roles and styles

- **syntax-role-vocabulary**: The syntax-role vocabulary MUST have exactly ten roles, named `keywords`, `commands`, `types`, `attributes`, `variables`, `values`, `numbers`, `strings`, `characters` and `comments`, in that declaration order.
- **syntax-role-names**: Each syntax role's name MUST equal the name of the corresponding syntax field of the editor's own theme model verbatim, so a consumer maps a role across without a translation table.
- **syntax-style-shape**: A syntax style MUST carry exactly a color, a bold flag and an italic flag; it MUST NOT carry underline or strikethrough.
- **syntax-style-defaults**: Constructing a syntax style from a color alone MUST default its bold and italic flags to `false`.
- **syntax-value-semantics**: A syntax role and a syntax style MUST be safe to pass across concurrency boundaries and compare for equality.

### The roleOverrides key grammar

- **override-key-spelling**: Computing the override key for a role and a bold/italic combination MUST return `syntax.` + the role's name, then `.bold` when bold is requested, then `.italic` when italic is requested — so the only four shapes written are `syntax.<role>`, `syntax.<role>.bold`, `syntax.<role>.italic` and `syntax.<role>.bold.italic`.
- **override-key-flag-order**: When reading, the grammar MUST treat the trailing segments as a set, so `syntax.comments.italic.bold` MUST parse identically to `syntax.comments.bold.italic`.
- **override-key-prefix**: A key MUST be recognised as a syntax key only when splitting it on `.` (keeping empty segments) yields at least two segments and the first segment is exactly `syntax`.
- **override-key-role**: A key whose second segment is not exactly a syntax role's name (case-sensitive) MUST NOT be recognised as a syntax key.
- **override-key-flag-vocabulary**: A key with any trailing segment other than `bold` or `italic` — including an empty segment — MUST NOT be recognised as a syntax key.
- **override-key-flag-once**: A key that states `bold` twice or `italic` twice MUST NOT be recognised as a syntax key.
- **override-key-no-throw**: An unrecognised key MUST be ignored — never treated as an error — and MUST NOT prevent a well-formed syntax key in the same map from being read.
- **override-key-collision-free**: The `syntax` namespace MUST NOT collide with the theme's semantic-role keys; the source relies on those role names being identifiers that cannot contain a dot.

### Reading and writing syntax styles

- **syntax-styles-read**: Reading a theme's syntax styles MUST return one style per role that has at least one recognised key in its override map, with the key's color and the bold/italic flags the key names.
- **syntax-styles-empty**: Reading a theme's syntax styles MUST return an empty map for a theme with no recognised syntax key.
- **syntax-styles-tiebreak**: When more than one recognised key names the same role, reading syntax styles MUST resolve to the lexicographically greatest key (so `syntax.keywords.italic` beats `syntax.keywords.bold`, which beats `syntax.keywords`), independent of map iteration or insertion order.
- **syntax-styles-invisible-to-roles**: Syntax keys MUST NOT cause the semantic palette to report any semantic role as declared, because the palette looks roles up strictly by role name.
- **syntax-styles-travel**: Syntax keys MUST survive a theme serialize/deserialize round trip unchanged, because they live in the theme's override map, which the theme's own encoding covers; this is what carries them through exporting a theme and duplicating a theme.
- **with-syntax-styles-replace**: Replacing a theme's syntax styles MUST remove every key the grammar recognises as a syntax key before writing the new styles, so the result carries exactly the given styles and no stale shape survives.
- **with-syntax-styles-preserve**: Replacing syntax styles MUST leave every other override-map entry unchanged, including a `syntax.`-prefixed key the grammar rejects (for example `syntax.keywords.underline`).
- **with-syntax-styles-write**: Replacing syntax styles MUST write each style under its computed override key, with the style's color as the value.
- **with-syntax-styles-clear**: Replacing syntax styles with an empty set MUST remove every recognised syntax key and nothing else.
- **with-syntax-styles-copy**: Replacing syntax styles MUST return a modified copy and MUST NOT mutate the original theme.
- **syntax-grammar-shared**: Reading syntax styles and replacing them MUST use the same parser, so the set of keys one reads is exactly the set the other replaces.

### VS Code import: entry points

- **import-bytes-entry**: Parsing from raw bytes MUST produce a theme or fail with an error.
- **import-jsonc**: Both parsing entry points MUST accept JSONC — `//` and block comments and trailing commas — and MUST produce the same theme a strict-JSON spelling of the same document produces.
- **import-encodings**: Both parsing entry points MUST accept UTF-8, UTF-8 with a byte-order mark, and UTF-16 payloads (including UTF-16 JSONC), producing the same theme as the UTF-8 spelling, decoded through the shared JSONC preprocessor (see [JSONC Preprocessor](adtoolkit://cookbook/foundation/formats/jsonc-preprocessor)).
- **import-bytes-ignores-include**: Parsing from raw bytes MUST NOT resolve an `include` key and MUST NOT reject a document for carrying one; the result MUST equal the result for the same document without the key.
- **import-file-entry**: Parsing from a file location MUST read the file, resolve its `include` chain, and parse the merged document.
- **import-file-default-root**: When no containment root is given, the containment root MUST be the theme file's own directory.
- **import-file-url-precondition**: The top-level file location is a caller precondition: the importer MUST NOT containment-check it — only `include` targets are checked. The shipping caller resolves the manifest's declared path against the extension's resource-path rules before calling (see [Extension Resource Path](adtoolkit://cookbook/workspace/extensions/manifest/extension-resource-path)).
- **import-name-from-label**: The imported theme's name MUST be the given label; the theme file's own `name` and `type` keys MUST be ignored.
- **import-lock-flags**: Parsing MUST return a theme that is neither built-in nor already marked imported, carrying a freshly generated identifier.

### VS Code import: validation and errors

- **import-validation-order**: The importer MUST check, in this order, and fail on the first failure: root is an object; `colors` is an object; `editor.foreground` is present and parses; `editor.background` is present and parses; foreground differs from background; all sixteen ANSI keys are present and parse.
- **import-syntax-error-passthrough**: When no candidate encoding yields a parseable JSON document, the importer MUST propagate the underlying JSON-parsing error for the raw bytes unchanged; it is not wrapped in an import-specific error.
- **import-root-object**: A document whose root is not a JSON object MUST fail with a not-an-object error.
- **import-colors-object**: A document whose `colors` member is absent, `null`, or not an object MUST fail with a missing-colors error.
- **import-foreground-required**: An absent or unparseable `editor.foreground` MUST fail with a missing-color error naming `editor.foreground`.
- **import-background-required**: An absent or unparseable `editor.background` MUST fail with a missing-color error naming `editor.background`.
- **import-foreground-background-distinct**: A theme whose parsed foreground equals its parsed background MUST fail with a foreground-matches-background error.
- **import-ansi-complete**: When any of the sixteen `terminal.ansi*` keys is absent or unparseable, the importer MUST fail with a missing-ANSI-colors error carrying every missing key, in ANSI slot order; it MUST NOT synthesise a missing slot.
- **import-ansi-order**: The sixteen ANSI colours MUST be stored in the slot order `terminal.ansiBlack`, `Red`, `Green`, `Yellow`, `Blue`, `Magenta`, `Cyan`, `White`, then the eight `terminal.ansiBright*` keys in the same colour order.
- **import-file-errors**: A file-read failure for the top-level file or any included file MUST propagate the underlying read error unchanged.
- **import-error-descriptions**: An import error MUST NOT provide a localized description of its own; a caller that requests one gets a generic, non-localized description of the failure case.

### VS Code import: palette mapping

- **import-appearance**: `uiTheme` MUST decide appearance: `vs-dark` and `hc-black` MUST yield dark; `vs` and `hc-light` MUST yield light.
- **import-appearance-fallback**: Any other `uiTheme` value MUST yield dark when the parsed background is dark and light otherwise.
- **import-cursor**: The cursor color MUST be `editorCursor.foreground` when present and parseable, and the foreground otherwise.
- **import-selection-source**: The declared selection MUST be `editor.selectionBackground` when present and parseable, else `editor.inactiveSelectionBackground` when present and parseable.
- **import-selection-opaque**: A declared selection MUST be stored composited over the background, so the stored value is opaque (alpha byte `FF`).
- **import-selection-fallback**: With neither selection key usable, the selection MUST be the background blended 20% toward the foreground.
- **import-role-overrides**: The importer MUST map exactly these six keys to semantic theme role overrides: `sideBar.background` → `surface`, `editorWidget.background` → `elevatedSurface`, `input.background` → `controlBackground`, `descriptionForeground` → `secondaryText`, `input.placeholderForeground` → `placeholderText`, `focusBorder` → `outline`.
- **import-role-overrides-present-only**: A mapped key MUST become an override only when it is present and parses; an absent or unparseable key MUST write nothing.
- **import-no-other-roles**: The importer MUST NOT write an override for any other semantic theme role — in particular not `windowBackground`, `primaryText`, `selection`, `accent`, `danger`, `border` or `warning` — even when a tempting VS Code key (`textLink.foreground`, `errorForeground`, `contrastBorder`, `editorWarning.foreground`) is present.

### VS Code import: colour decoding

- **hex-forms**: A colour string MUST parse, with or without a leading `#`, when it has 3, 4, 6 or 8 hex digits: 3 and 4 digits MUST be expanded by doubling each digit, and a 6-digit value MUST receive an opaque `FF` alpha.
- **hex-invalid-absent**: A colour value that is not a string, or a string of any other length or containing non-hex characters (a named colour, an odd digit count), MUST count as absent — never as an error of its own.
- **hex-shared**: `colors` values and `tokenColors` `foreground` values MUST go through the same normaliser.

### VS Code import: syntax styles from tokenColors

- **token-rules-source**: Syntax rules MUST be read from the root-level `tokenColors` array; a `tokenColors` that is absent or not an array MUST yield no rules.
- **token-rule-usable**: A `tokenColors` entry MUST become rules only when it is an object whose `settings` is an object whose `foreground` is a string that parses as a colour; any other entry — including one with only a `fontStyle` — MUST be skipped without affecting the others.
- **token-scope-forms**: An entry's `scope` MUST be accepted as an array (taking each string element and skipping non-strings) or as a single string split on commas; any other `scope`, including an absent one, MUST yield no rules for that entry.
- **token-selector-clean**: Each selector MUST be trimmed of surrounding whitespace and newlines; an empty selector, or one still containing whitespace (a descendant selector such as `meta.tag entity.name`), MUST be dropped without dropping the entry's other selectors.
- **token-emphasis**: `fontStyle` MUST be split on whitespace; the style MUST be bold when a token equals `bold` and italic when a token equals `italic`; every other token (`underline`, `strikethrough`, `normal`, `regular`, unknown words) MUST be ignored.
- **token-match**: A rule MUST apply to a queried scope when its selector equals the scope or is a dot-separated ancestor of it (the scope begins with selector + `.`).
- **token-specificity**: Among applicable rules the longest selector MUST win regardless of declaration order.
- **token-tiebreak**: Among applicable rules of equal selector length, the one later in document order MUST win.
- **token-scope-chain**: Each role MUST be resolved from this ordered scope chain: `keywords` ← `keyword.control`; `commands` ← `entity.name.function`; `types` ← `entity.name.type`, then `support.type`; `attributes` ← `entity.other.attribute-name`; `variables` ← `variable.other`; `values` ← `constant.language`; `numbers` ← `constant.numeric`; `strings` ← `string.quoted.double`; `characters` ← `constant.character`; `comments` ← `comment.line`.
- **token-chain-first-match**: A later scope in a role's chain MUST be consulted only when no rule applies to any earlier scope; an ancestor-only match on an earlier scope (for example a rule for `entity` matching `entity.name.type`) MUST win over an exact match on a later scope.
- **token-unmatched-role**: A role no rule matches MUST get no syntax style, leaving the consumer's ANSI derivation in charge.
- **token-no-throw**: `tokenColors` handling MUST NOT fail with an error; a malformed `tokenColors` yields no styles and the rest of the theme is unchanged.
- **token-stored-as-overrides**: The resolved syntax styles MUST be stored by replacing syntax styles, so they appear as `syntax.*` keys in the override map alongside the six role overrides and change no palette field.

### VS Code import: include chains

- **include-detect**: A document MUST be treated as including another only when its `include` value is a non-empty string; any other value MUST be treated as no include.
- **include-resolve**: An include path MUST be resolved relative to the including file's directory and MUST stay inside the containment root (see [Extension Resource Path](adtoolkit://cookbook/workspace/extensions/manifest/extension-resource-path)).
- **include-containment**: An include that resolves outside the containment root MUST fail with an escapes-containment-root error.
- **include-depth-bound**: The importer MUST follow at most 8 include hops; a document at depth 8 that still names an include MUST fail with an include-chain-too-deep error (limit 8).
- **include-cycle**: A cycle (`a.json` including `b.json` including `a.json`) MUST be stopped by the depth bound and fail with the same include-chain-too-deep error (limit 8); there is no visited-set.
- **include-merge-colors**: When both files carry a `colors` object, the merged `colors` MUST be the base's keys overlaid key by key with the including file's, the including file winning.
- **include-merge-tokens**: When either file carries a `tokenColors` array, the merged `tokenColors` MUST be the base's entries followed by the including file's.
- **include-merge-other**: Every other top-level key of the including file MUST override the base's value outright.
- **include-consumed**: The `include` key MUST NOT appear in the merged document.

### Storing an imported theme

- **store-import**: Importing a VS Code theme into storage MUST parse the file using the default containment root, mark the result as imported, append it to the theme store, and return the stored theme.
- **store-import-locked**: The stored theme MUST report itself as locked and not editable.
- **store-import-failure**: When parsing fails, importing MUST propagate the error and MUST NOT write to storage.
- **store-import-no-rename**: Importing MUST NOT de-duplicate the theme's name against existing themes; the name is the given label verbatim.

### Concurrency

- **importer-isolation**: The importer holds no shared mutable state, so its parse operations MUST be callable from any thread and MUST run synchronously on the calling thread, including any blocking file reads.
- **importer-no-limits**: The importer MUST NOT impose a timeout, a file-size limit or cancellation; a parse runs to completion or fails.
- **store-isolation**: Importing a theme into the theme store MUST run on the store's single designated thread, so its file reads block that thread.
- **storage-isolation**: The settings-backed storage MUST confine every property access to that same single designated thread.

### UserSettings-backed storage

- **storage-custom-themes-key**: The custom-themes storage property MUST read and write the settings store's custom-themes setting — key `theme.custom_themes`, a JSON-encoded list of themes, default an empty list — in whichever provider the settings store holds (see [Settings Storage](adtoolkit://cookbook/foundation/settings-storage)).
- **storage-active-key**: The active-theme-id storage property MUST read and write the settings store's active-theme-id setting — key `theme.active_theme_id`, a plain string, default the built-in catalog's default theme id.
- **storage-legacy-compatible**: The keys and encodings MUST NOT change; a value written by an earlier build under either key MUST read back unchanged, and a write MUST land under the historical key as a plain string for the active id.
- **storage-nil-write**: Clearing the active-theme-id property MUST store the built-in catalog's default theme id, never leave it empty.
- **storage-read-non-nil**: Reading the active-theme-id property MUST always return a string — the stored value, or the built-in catalog's default theme id when nothing is stored.
- **storage-observers-lazy**: The storage MUST NOT observe either setting until an external-change callback is set to a non-empty value, and MUST release both observers when the callback is cleared.
- **storage-observers-rebuilt**: Each time a non-empty external-change callback is assigned, it MUST replace both observers with fresh ones.
- **storage-change-any-writer**: Once hooked, the external-change callback MUST fire on every change to either setting — including a write made through this storage itself — not only on writes from outside this storage seam.
- **storage-change-deferred**: The external-change callback MUST be delivered on the main work queue after the new value has landed, not synchronously inside the write.
- **storage-change-no-initial**: Hooking the external-change callback MUST NOT invoke it for the values already stored.
- **storage-weak-owner**: The observers MUST NOT keep the storage alive on their own, so once the storage no longer exists, no further callbacks are delivered.

### Convenience initialisers

- **store-default-init**: Constructing the theme store with no explicit storage MUST be equivalent to constructing it with the settings-backed storage.
- **manager-default-init**: On a desktop platform, constructing the theme manager with no explicit storage or appearance driver MUST be equivalent to constructing it with the settings-backed storage and that platform's own appearance driver, whose automatic-appearance signal reads the settings store's appearance-mode setting fresh each time it is consulted.
- **manager-default-reads-disk**: A theme id stored under the active-theme-id key by an earlier build MUST be the current theme of a freshly constructed default theme manager.

