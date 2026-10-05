
- **placeholder-substitution**: the localization function MUST return the
  manifest bytes with every `%key%` placeholder that the merged
  localization table for the manifest's directory/locale can answer
  replaced by the string that key stands for.
- **no-throw-contract**: the localization function MUST NOT be able to
  fail outright, and MUST return a value for every input; a missing,
  unreadable, or malformed localization table MUST cost the manifest its
  translations and nothing else, and MUST NOT propagate an error to its
  caller.
- **unchanged-when-no-table**: the localization function MUST return the
  manifest bytes unchanged, byte for byte, without parsing or
  re-serializing them, when the merged table for the directory/locale is
  empty.
- **unchanged-when-unparseable-input**: the localization function MUST
  return the manifest bytes unchanged when the manifest's own bytes cannot
  be parsed as JSON/JSONC.
- **unchanged-when-unserializable-output**: the localization function MUST
  return the manifest bytes unchanged when the substituted tree cannot be
  re-serialized to JSON.
- **default-locale-is-current**: the localization function's locale
  parameter MUST default to the reader's current locale when the caller
  supplies none.
- **table-search-order**: The table filenames searched for a given
  locale, least specific first, MUST be `package.nls.json`, then
  `package.nls.<language>.json` when the locale has a language code, then
  `package.nls.<language>-<region>.json` when the locale additionally has a
  region.
- **language-code-absent-limits-search**: the table-name lookup MUST
  return only `["package.nls.json"]` when the locale has no resolvable
  language code.
- **default-table-not-overwritten**: A key present only in the default
  (`package.nls.json`) table MUST remain available in the merged table even
  when a more specific table for the same locale is also present.
- **more-specific-table-wins**: For a key present in more than one table
  that applies to the locale, the value from the most specific table
  (region-and-language over bare-language over default) MUST be the one
  the merged table returns.
- **table-filename-case-insensitive**: A table file on disk MUST be
  matched against its expected name without regard to case.
- **missing-table-file-contributes-nothing**: A table filename with no
  case-insensitively matching entry in the directory's contents MUST be
  skipped, contributing no entries and not failing the merge.
- **unreadable-directory-yields-no-tables**: the directory-listing step
  MUST yield no tables at all when it cannot list the directory's
  contents, so a nonexistent or unreadable directory MUST be treated
  identically to one with no localization tables at all.
- **unreadable-table-file-contributes-nothing**: reading one table's
  entries MUST yield none when the table's bytes cannot be read from its
  location.
- **malformed-table-contributes-nothing**: reading one table's entries
  MUST yield none when the table's contents cannot be parsed as
  JSON/JSONC, or when the parsed value is not a string-keyed object.
- **table-supports-jsonc**: A table file MUST be parsed with JSONC
  tolerance, so a table written with `//` comments or a trailing comma
  MUST be read the same as strict JSON.
- **table-entry-two-value-shapes**: A table entry MUST resolve to a string
  when its JSON value is either a bare string or an object with a
  `message` string field, and MUST be dropped from the table for any other
  JSON shape.
- **substitution-walks-full-tree**: Substitution MUST be applied to every
  string value at every depth of the parsed manifest tree, including
  inside arrays and inside objects nested arbitrarily deep — for example, a
  value five levels down at
  `contributes.configuration[].properties.<setting>.description`.
- **object-keys-never-substituted**: Substitution MUST be applied only to
  a JSON object's values, never to its keys, regardless of whether a key's
  text would otherwise match the placeholder pattern.
- **non-string-values-pass-through**: A JSON value that is not a string —
  `null`, a boolean, a number, an array, or an object — MUST be returned
  from substitution with its own kind unchanged, with substitution applied
  only to any string values nested inside it.
- **placeholder-must-be-whole-string**: A string MUST be treated as a
  placeholder reference only when its entire content, not a prefix,
  suffix, or substring, is a single `%…%` token — longer than two
  characters and starting and ending with `%`.
- **placeholder-key-rejects-embedded-percent**: A candidate placeholder
  whose extracted key — the text between the leading and trailing `%` —
  itself contains a `%` character MUST be returned unchanged rather than
  looked up.
- **unresolved-placeholder-left-visible**: A placeholder string whose
  extracted key has no entry in the merged table MUST be returned
  unchanged, leaving the literal `%key%` text visible in the output rather
  than substituting an empty string.
- **identifying-fields-not-reference-shaped**: A manifest string that is
  not itself written in `%key%` form MUST NOT be substituted even when the
  merged table happens to hold an entry whose key equals that string's
  literal text (the whole-string test rejects it before any lookup).

