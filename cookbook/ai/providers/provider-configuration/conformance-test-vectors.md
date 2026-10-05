
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-configuration-001 | identifier-assignment | Construct two configurations with matching `name`, `pluginIdentifier`, `templateId` and no `id` argument supplied | Each construction produces a non-empty `id`; the two `id` values differ |
| ai-provider-configuration-002 | identifier-immutability | Attempt to assign a new value to an existing configuration's `id` after construction | Not permitted — `id` has no setter |
| ai-provider-configuration-003 | stable-identity | Bind a configuration to a context that renders a list keyed by identity, then read its `id` | Works with no adapter; the value used for identity equals `id` directly |
| ai-provider-configuration-004 | display-name-mutability | Construct a configuration, capture its `(id, pluginIdentifier, templateId)`, then reassign only `name` | `name` updates to the new value; `(id, pluginIdentifier, templateId)` are unchanged |
| ai-provider-configuration-005 | plugin-and-template-identity-immutability | Attempt to assign a new value to an existing configuration's `pluginIdentifier` or `templateId` | Not permitted — neither has a setter |
| ai-provider-configuration-006 | no-content-validation | Construct a configuration with `name`, `pluginIdentifier`, and `templateId` all set to an empty string | Construction succeeds with no error; all three fields read back as empty strings |
| ai-provider-configuration-007 | json-round-trip | Encode an array containing one configuration (random `id`, non-empty `name`/`pluginIdentifier`/`templateId`) to JSON, then decode it back | The decoded array equals the original |
| ai-provider-configuration-008 | concurrency-safe | Capture a configuration value in a closure or task handed off to run concurrently, under strict concurrency checking | No safety diagnostic is raised |
| ai-provider-configuration-009 | value-equality | Construct two configurations with identical `name`, `pluginIdentifier`, `templateId` but each given its own freshly generated `id` | The two values compare unequal, because equality includes `id` |
| ai-provider-configuration-010 | value-hashing | Insert two configurations that compare equal (copied from one instance, so all four fields match) into a set | The set contains one entry |
| ai-provider-configuration-011 | value-semantics | Construct a configuration `a`, copy it to `b`, then reassign `a`'s `name` | `b.name` is unchanged; `a.name` reflects the new value |
| ai-provider-configuration-012 | no-persistence | Inspect the record's own logic for any settings-store, secure-storage, file, or network call | None is present; the record touches no persistence or networking API of its own |
| ai-provider-configuration-013 | no-registry-validation | Construct a configuration with a `pluginIdentifier` and `templateId` that match no installed plugin or template | Construction succeeds with no error, warning, or lookup performed |
| ai-provider-configuration-014 | unique-name-unchanged-when-free | Derive a unique name for candidate "Groq" against an empty taken set | "Groq" |
| ai-provider-configuration-015 | unique-name-suffix-on-collision | Derive a unique name for candidate "Groq" against a taken set containing "Groq" | "Groq 2" |
| ai-provider-configuration-016 | unique-name-suffix-increments | Derive a unique name for candidate "Groq" against a taken set containing "Groq" and "Groq 2" | "Groq 3" — a direct consequence of trying successive suffixes until one is free |
| ai-provider-configuration-017 | unique-name-static-purity | Derive a unique name for candidate "Groq" against a taken set containing "Groq", twice in immediate succession, with no configuration instance involved | Both calls return "Groq 2"; no state changes between calls |
| ai-provider-configuration-018 | json-round-trip, value-equality (external-store evidence) | Construct a configuration, store it as the sole entry of the app's configuration list, and record its `id` as the selected configuration | The stored list contains exactly that configuration, and the selected-configuration record equals its `id`; this round-trips through an external store, not through the record's own logic |

