
- **url-shaped-fields-decoded-as-string**: A search entry's `files`, and an
  extension detail's `downloads` and `files`, MUST decode as an optional
  string-to-string mapping, never as a mapping of parsed URLs, so a value
  that cannot parse as a URL costs only the computed accessor that reads it
  and never the decode of the entry or the page containing it.
- **search-entry-identifier-case-folded**: A search entry's identifier MUST
  return its namespace and name joined by a `.` and lowercased.
- **search-entry-icon-url-resolves-independently**: A search entry's icon
  URL MUST return the parsed URL when its `files["icon"]` value is present
  and parseable, and MUST return nothing, never fail, when the key is absent
  or the string is unparseable.
- **search-page-total-size-is-whole-result-set**: A search page's total
  size MUST report the size of the entire result set the query matched, not
  the number of elements in that page's extension list, so a caller can
  decide whether to request another offset.
- **search-page-array-decode-is-all-or-nothing**: A search page's extension
  list MUST decode as a single unit that fails for the whole page when any
  one element is missing a required field (namespace, name, or version) or
  gives it the wrong type — this concept implements no per-element recovery
  the way it does for a single URL-shaped field (contrast with
  **url-shaped-fields-decoded-as-string**).
- **extension-detail-identifier-case-folded**: An extension detail's
  identifier MUST return its namespace and name joined by a `.` and
  lowercased, and, for the same namespace and name, MUST equal the search
  entry's identifier, so a search row and a detail record for the same
  extension join without either side re-deriving the case-folding rule (see
  **search-entry-identifier-case-folded**).
- **license-field-carries-absence**: An extension detail's license MUST
  decode to nothing when the `license` key is absent, and MUST preserve
  whatever string the registry sent verbatim — including an empty string —
  when the key is present, with no normalization between the two.
- **semantic-version-nil-on-non-semver**: An extension detail's parsed
  semantic version MUST return nothing, never fail or substitute a default,
  when its `version` field does not parse as a semantic version.
- **engine-range-nil-when-absent-or-unparseable**: An extension detail's
  engine range MUST return nothing both when `engines` is absent or has no
  `vscode` key, and when the `vscode` value is present but does not parse as
  an engine range, drawing no distinction between those two cases at this
  property; the distinction between "not gated" and "unreadable" is drawn
  only by the installability verdict.
- **universal-download-is-the-only-download-url-exposed**: An extension
  detail's universal download URL MUST return the parsed URL for
  `downloads["universal"]` only, and MUST return nothing when that key is
  absent, even when `downloads` holds one or more other platform-keyed
  entries.
- **file-urls-resolve-per-named-key**: The digest, signature, public-key,
  license-text, readme, and icon URLs on an extension detail MUST each
  resolve independently through a shared file-URL lookup reading `files[key]`,
  and MUST each return nothing on its own — with no effect on any other
  accessor — when its own key is absent or its value is unparseable.
- **web-extension-kind-is-advisory-only**: Whether an extension declares the
  web extension kind MUST report whether the registry's `extensionKind`
  array contains the string `"web"`, and the installability verdict MUST NOT
  read `extensionKind` or this flag at all when computing its verdict.
- **installability-checks-platform-before-download-existence**: The
  installability verdict MUST return "platform-specific" (naming the
  platform) when `targetPlatform` is present and not equal to the literal
  string `"universal"`, and MUST perform this check before checking whether
  a universal download exists.
- **installability-requires-a-universal-download**: The installability
  verdict MUST return "no universal build" when the universal download URL
  is absent, checked after the platform check and before any engine check.
- **installability-engine-gate-skipped-when-absent-or-empty**: The
  installability verdict MUST treat an absent `engines["vscode"]` and an
  empty-string `engines["vscode"]` identically: both MUST skip the engine
  check entirely rather than being treated as an unparseable range.
- **installability-engine-range-unreadable-carries-raw-string**: The
  installability verdict MUST return "engine range unreadable," carrying the
  exact `engines["vscode"]` string, when that string is non-empty and does
  not parse as an engine range.
- **installability-engine-incompatible-carries-parsed-range**: The
  installability verdict MUST return "engine incompatible," carrying the
  parsed engine range, when the range parses but does not accept the host
  version.
- **installability-default-is-installable**: The installability verdict
  MUST return "installable" when the platform check, the download-existence
  check, and the engine check (when applicable) all pass.
- **installability-is-pure-and-synchronous**: The installability verdict
  MUST compute its result solely from the extension detail's already-decoded
  fields and the supplied host version, MUST return synchronously, and MUST
  NOT perform file, network, or process access.
- **is-installable-reflects-only-the-installable-case**: The "is
  installable" flag derived from the verdict MUST return true if and only if
  the verdict is "installable," and MUST return false for every other case.
- **installability-refusal-cases-are-named-not-freeform**: The
  installability verdict MUST expose one distinct case per refusal reason
  (engine incompatible, engine range unreadable, platform-specific, no
  universal build) rather than a flag paired with a freeform message, so a
  caller can distinguish and separately present each reason without parsing
  prose.
- **catalog-types-are-safe-for-concurrent-use**: The search entry, search
  page, extension detail, and installability verdict MUST each be a
  concurrency-safe value that supports equality comparison, with no
  confinement to a single execution context, and decoding MUST be a
  synchronous, side-effect-free function of the input handed to it, so a
  decoded value MAY be passed freely across concurrent contexts and MAY be
  decoded concurrently by independent callers with no external coordination.

