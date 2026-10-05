
- **Null/empty contributions**: when the contribution point's contributed
  identifiers is empty (no extension has contributed a language),
  `languageIdentifiers` MUST still return the full built-in set plus the
  default identifier; it MUST NOT return an empty list
  (`default-language-inclusion`, `hlv-002`).
- **Boundary values**: MUST NOT apply a maximum length or count to
  `languageIdentifiers`; any number of contributed identifiers, including
  one that duplicates every built-in identifier, MUST be accepted and
  deduplicated the same way a single duplicate is (`contributed-deduplication`).
- **Concurrent access**: this component is confined to a single serialized
  execution domain, so every read of `languageIdentifiers` and every read
  of the stored contribution point executes serialized; concurrent calls
  from other isolation domains MUST NOT compile without a hop, and the
  type defines no additional locking because the domain already serializes
  access; see Platform Notes for how the confinement is enforced.
- **Error states**: not applicable in the throwing or optional-unwrapping
  sense — `languageIdentifiers` is a synchronous, non-throwing computed
  value with no failure path; every input it consumes (the catalogue's
  full language list, its default language, the contribution point's
  contributed identifiers) is already a plain, non-optional list or string
  by the time this type reads it.
- **Offline/disconnected**: not applicable — this component performs no
  networking and touches no filesystem; the catalogue's full language list
  is linked-in package data and the contribution point's contributions
  were already parsed and applied before this type reads them.

