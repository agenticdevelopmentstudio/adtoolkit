
- **protocol-conformance**: This component MUST conform to the
  language-vocabulary protocol, exposing exactly one member, a
  `languageIdentifiers` list of strings.
- **built-ins-first-ordering**: `languageIdentifiers` MUST list every
  identifier drawn from the catalogue's full language list before any
  identifier drawn from the contribution point's contributed identifiers,
  in the catalogue list's own order.
- **built-in-deduplication**: while building the built-in portion, an
  identifier already added from an earlier entry in the catalogue list
  MUST NOT be appended again; this step MUST track seen identifiers in a
  set and append only when insertion into that set reports a new member.
- **default-language-inclusion**: `languageIdentifiers` MUST include the
  catalogue's default-language identifier, even though the catalogue's
  full language list does not itself contain the default language.
- **default-language-position**: the default identifier MUST be appended
  immediately after the built-in step completes and before any contributed
  identifier is considered, and MUST be skipped if it was already added
  (e.g. because a future release of the catalogue includes it in its full
  language list), using the same seen-set the built-in step populated.
- **contributed-deduplication**: an identifier from the contribution
  point's contributed identifiers that duplicates an identifier already
  added from the built-in or default portion MUST NOT be appended a second
  time; it MUST appear only once, at its earlier (built-in or default)
  position.
- **contributed-order-preservation**: contributed identifiers that are not
  already present MUST be appended in exactly the order the contribution
  point returns them, with no re-sorting or re-grouping performed by this
  component itself.
- **tsname-exclusion**: `languageIdentifiers` MUST be built from the
  catalogue's own language-identifier field, never from its shared
  grammar-name field; identifier values are used because the grammar-name
  field names a shared tree-sitter grammar rather than a language, and
  several distinct languages (JSX and JavaScript, TSX and TypeScript, an
  OCaml interface and OCaml) share one grammar name while each keeps its
  own identifier.
- **host-vocabulary-fidelity**: `languageIdentifiers` MUST return this
  host's own identifiers as the catalogue and the contribution point
  define them (for example `cSharp`, `jsx`, `tsx`, `objc`, `bash`, `goMod`,
  `jsdoc`, `markdownInline`, `regex`) rather than identifiers translated
  into whatever spelling `vscode.d.ts` or a real VS Code installation would
  use for the same language.
- **computed-not-cached**: `languageIdentifiers` MUST be recomputed from
  the catalogue's full language list, its default language, and the
  contribution point's contributed identifiers on every access; it MUST
  NOT read from or write to any stored, cached copy of the result, because
  the contribution point's contributions can change between calls as
  extensions load and unload.
- **init-dependency**: Constructing this component MUST take the
  contribution point as its sole constructor argument and MUST store it
  for the instance's lifetime as the only source `languageIdentifiers`
  consults for contributed identifiers.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

