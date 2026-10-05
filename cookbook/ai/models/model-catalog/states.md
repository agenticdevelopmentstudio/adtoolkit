
Not applicable — this is a data lookup table (an immutable, in-memory value
model), not a visual component. The one runtime distinction this component
has — "resource loaded" versus "resource missing/unreadable/malformed, fell
back to empty" — is captured under Behavioral Requirements
(`shared-catalog-never-fails-to-exist`, `load-is-total`), not as a
visual-state table.

