
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ai-provider-config-keys-001 | field-key-format | Configuration identifier `11111111-2222-3333-4444-555555555555`, field name `"apiKey"`; call the field-key operation | `"aiplugin.config.11111111-2222-3333-4444-555555555555.field.apiKey"` |
| ai-provider-config-keys-002 | model-key-format | Same configuration identifier as above; call the model-key operation | `"aiplugin.config.11111111-2222-3333-4444-555555555555.model"` |
| ai-provider-config-keys-003 | secret-fields-key-format | Same configuration identifier; call the secret-fields-key operation | `"aiplugin.config.11111111-2222-3333-4444-555555555555.secretfields"` |
| ai-provider-config-keys-004 | fields-key-format | Same configuration identifier; call the fields-key operation | `"aiplugin.config.11111111-2222-3333-4444-555555555555.fields"` |
| ai-provider-config-keys-005 | registry-keys-fixed | Read the selected-configuration-id key, configurations key, enabled key, and legacy-cleaned key | `"ai_selected_config_id"`, `"ai_configurations"`, `"ai_summaries_enabled"`, `"ai_legacy_cleaned"` respectively |
| ai-provider-config-keys-006 | key-namespace-isolation | Call the field-key operation with two different configuration identifiers and the same field name | Two distinct strings, since two distinct configuration identifiers never share the same canonical string form |
| ai-provider-config-keys-007 | fields-ledger-format | A test double seeds the fields-key ledger with a set of field names joined by `\n`, then the daemon's chat-completion path reads it back by splitting on `\n` | The recovered field-name set equals the original set exactly |
| ai-provider-config-keys-008 | secret-fields-key-consumer | Search the given sources for every reference to the secret-fields-key operation | Only its declaration and a format-only check appear; no production writer or reader exists |
| ai-provider-config-keys-009 | pure-computation, no-error-domain | Call the field-key operation twice in immediate succession with the same arguments | Both calls return the identical string; no error is raised and no state changes between calls |
| ai-provider-config-keys-010 | concurrency-isolation | Call the model-key operation from several concurrent execution contexts with no suspension | Every call observes the same result, with no concurrency-safety diagnostic, because the component holds no stored state |
| ai-provider-config-keys-011 | no-instantiation | Attempt to construct an instance of this component | Fails: the component is a namespace with no instance to construct |
| ai-provider-config-keys-012 | field-name-newline-safety | Call the field-key operation with a field name containing `\n`, whose returned key's value is later folded into a fields-key ledger and parsed by splitting on `\n` | The key is produced without error; the ledger parses as two entries instead of one field key, because the component applies no guard |
| ai-provider-config-keys-013 | single-source-of-truth-usage (documented deviation) | Search the codebase for the literal `"ai_summaries_enabled"` outside this component | A separate settings-configuration component duplicates the literal independently rather than referencing this component's enabled key — the one known deviation from this SHOULD, documented in Design Decisions |

