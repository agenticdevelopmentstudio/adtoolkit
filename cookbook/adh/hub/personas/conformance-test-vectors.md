
| Input | Expected output / effect | Traced to |
|-------|---------------------------|-----------|
| Listing the root level with personas Ada and Bob present | A navigation level whose items are labeled "Ada" and "Bob", subtitled "ada" and "bob", with empty message "No personas yet." and a create action titled "New Persona" | `testRootLevelListsPersonas` |
| Resolving child content for a path naming persona Ada | A facet-rail level with id `"persona-topics"`, title `"Ada"`, item ids exactly `identity, description, personality, purpose, project, knowledge, memory, abilities, permissions, access, demo, chatStatus, llm` | `testPersonaChildIsFacetRail` |
| Identity form: set `name` to `"Ada Lovelace"`, `visibility` to `"hub"`, save | The resulting update payload has `name == "Ada Lovelace"`, `visibility == "hub"`, `modelPrompt == "You are Ada."` (untouched, rides along) | `testIdentityFormValuesAndSave` |
| Identity slug field validated against `"Bad Slug"` | Validation fails with the slug pattern's own message | `testIdentityFormValidatesSlug` |
| Delete action performed on Ada's identity facet | The delete action's confirmation text reads exactly `Delete persona "Ada"? This cannot be undone.`; the delete request names persona `"persona.me.ada"` | `testIdentityDeleteAction` |
| Personality form: `voice = "   "`, `character = "Curious"`, save | The saved payload has `voice` absent and `character == "Curious"` | `testBlankTextBecomesNilOnSave` |
| LLM form: clear `serviceId` to `""`, save | The saved payload has `serviceId` and `model` both absent | `testLLMSaveClearsModelWhenServiceHasNoSuchModel` |
| Resolving child content for each of the 8 unsupported facet ids | The detail form's sole value, keyed `"notice"`, equals `"Not available in this version"`; no form specification exists for that facet | `testUnsupportedFacetsShowNotice` |
| Performing the persona-creation form's save action with `name: "Bob"`, `slug: "bob"`, empty `description`, and `modelPrompt: "You are Bob."` | The resulting create payload has `description` absent, `model == ""`, and `visibility == "private"` | `testCreateSpecAndPerform` |
| Decode a persona payload with extra fields `userId`/`ownerKind`/`ownerId` | Decode succeeds; the resulting record's `name == "Ada"`, the unknown fields are dropped, and `cannedChat` decodes to the opaque JSON object `{"mode": "script", "turns": []}` | `testPersonaDecodesFromWebJSON` |
| The demo-eligibility check, given `{ enabled: true, ink: { source: "* [unclosed\n", signInLine: "x" } }` | `true` — a syntax error in the ink script still advertises a demo | canned.test.ts, "does not compile the ink — a syntax error still advertises a demo" |
| The demo-eligibility check, given a well-formed but disabled config, and separately given `null` | both `false` | canned.test.ts, "is false for a parked script and for no config at all" |
| Parsing a chat-status configuration given `{ words: 7 }` | `{ words: [], icons: [] }` — malformed field dropped to an empty list, not substituted with the default | chat-status.test.ts, "drops a malformed words/icons field to an empty list rather than substituting the default" |
| Resolving a chat-status configuration for kind `"search"`, where the configuration has one word pair tagged `"search"` plus untagged defaults | `words` is the UNION of the tagged and untagged rows; `frames` resolves to the first matching icon set only | chat-status.test.ts, "unions rows tagged with the kind with untagged rows that fit anything" |

