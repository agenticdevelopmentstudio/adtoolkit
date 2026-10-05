
### The key function

- **key-input-shape**: The key function MUST accept any value that has a string `platform` field and a string `projectName` field; other fields on the value MUST be ignored.
- **key-format**: The key function MUST return the string formed by the `platform` value, then a single `|` character, then the `projectName` value, with no other characters added.
- **key-raw-platform**: The key function MUST use the `platform` value exactly as given, without canonicalizing case or spelling, so the key matches the raw platform carried in a deploy project entry and persisted as an ignored-project row.
- **key-no-trimming**: The key function MUST NOT trim, lowercase, escape or otherwise transform either field.
- **key-determinism**: The key function MUST return the same string for two inputs whose `platform` and `projectName` values are equal.
- **key-single-source**: Every place that builds or tests a project identity key (the review view's ignore collection and the provider's ignore filter) MUST derive the key through the key function rather than formatting it independently.

### The de-duplication function

- **unique-generic-element**: The de-duplication function MUST accept a list of entries of any type that has string `platform` and `projectName` fields, and MUST return a list of that same type.
- **unique-first-seen-wins**: When two or more entries produce the same key (via the key function), the de-duplication function MUST keep only the entry that appears first in the input list.
- **unique-order-preserved**: The de-duplication function MUST return the kept entries in the same relative order they had in the input list.
- **unique-identity-preserved**: The de-duplication function MUST return the original entry values, not copies or projections.
- **unique-new-array**: The de-duplication function MUST return a new list and MUST NOT mutate the input list.
- **unique-key-equality**: The de-duplication function MUST treat two entries as the same project if and only if their keys (via the key function) are equal; other fields (environment, domain) MUST NOT affect grouping.
- **unique-production-representative**: The de-duplication function MUST NOT reorder entries to choose a representative; the kept entry carries the production domain only because the backend orders a project's environments production-first, which is the backend's contract, not this logic's.

### Runtime and side effects

- **pure-functions**: Both functions MUST be synchronous and MUST have no side effects: no I/O, no network, no persistence, no logging and no shared state across calls.
- **no-errors-raised**: Both functions MUST NOT throw for well-typed input, and neither defines an error return.
- **per-call-state**: The de-duplication function MUST scope its seen-key tracking to a single call, so repeated calls are independent.

