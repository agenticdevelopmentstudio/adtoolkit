
- **Decision**: the extension's `state` text is stored and returned exactly
  as given, never parsed as JSON or re-serialized by this type.
  **Rationale**: the source's own doc comment states that this value "goes
  straight back into a `<script>` element on restore," so re-encoding it
  would reorder keys and re-escape characters — a different value than the
  one the extension saved, produced by a layer that the doc comment states
  "has no business reading it at all."
  **Approved**: pending
- **Decision**: the owning extension's identifier is not a stored field,
  even though every caller that has one available when constructing a
  `WebviewPanelState` could easily store it.
  **Rationale**: the source's doc comment states the identifier is
  derivable from `viewType` via the `onWebviewPanel:<viewType>` activation
  event, and a second copy of a derivable fact is one that can disagree with
  the first.
  **Approved**: pending
- **Decision**: a missing `viewType` key throws rather than decoding to an
  empty string or another placeholder, while a missing `title` or `options`
  key decodes to a defined default instead of throwing.
  **Rationale**: the source's doc comment on `init(from:)` draws this
  distinction explicitly — "a missing title is survivable — an untitled tab
  is still the user's tab. A missing view type is not: it names the
  serializer that knows how to rebuild this panel, and a default would hand
  the panel to whichever provider happened to answer to the empty string."
  This is also the reasoning behind the open question on
  `empty-view-type-validation`: it applies to a `viewType` key that is
  present but empty exactly as it does to one that is absent, and only the
  absent case is currently guarded.
  **Approved**: pending
- **Decision**: options absent from stored JSON decode to the safe,
  no-scripts, no-forms, default-roots posture rather than to whatever the
  most commonly-used options happen to be.
  **Rationale**: the source's doc comment states that an entry written
  before `options` existed is still a panel the user had open and must come
  back, "but what it must not do is come back with capabilities nobody
  recorded it having" — defaulting toward permissiveness would silently
  grant a restored panel scripting or file access its extension never
  declared.
  **Approved**: pending

**Decision**: An empty-string `viewType` decodes successfully; only a missing key is refused.
**Rationale**: `WebviewPanelState`'s decoder reads `viewType` with a plain string decode, so the empty string passes while the stated reason for refusing a missing key (a default would match whichever provider answers to the empty string) holds for it too. Closing it would take a maintainer decision on whether to refuse an empty `viewType`, and whether that needs a second error condition or can reuse the missing-key failure.
**Approved**: pending

