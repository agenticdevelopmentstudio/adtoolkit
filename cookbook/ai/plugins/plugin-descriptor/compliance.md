
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | Security |

`separation-of-concerns` passes because `AIPluginDescriptor.swift` performs no file I/O, network access, or persistence of its own — bundle discovery lives in `AIPluginManager`, and credential/setting storage lives in `PluginConfigStore`/`AIProviderConfigStore`; this file is only the decoded shape and its pure resolution helpers. `no-hardcoded-strings` fails: `resolvedConfigType` returns the literal, non-localized English strings `"API Key"` and `"Local"`, which the provider picker's Config Type column displays directly (see Localization). `data-integrity` is `partial`: `identifier`, `Field.key`, and `ProviderTemplate.id` carry no uniqueness or non-empty validation in this type — duplicates decode and construct successfully, and `AIPluginManager.template(pluginIdentifier:templateId:)` silently resolves to the first match on a colliding `id` (see Edge Cases). `secure-storage` is `partial`: `Field.Kind.secret` correctly signals which values downstream consumers MUST route to the Keychain (confirmed in `PluginConfigStore.swift`/`AIProviderConfigStore.swift`), but this type performs no storage or enforcement of its own — a consumer that ignored `isSecret` would not be caught by anything in this file.

`unit-test-coverage` passes because `AIPluginDescriptorTests.swift` covers decoding identity, models and typed fields, `resolvedDefaultModel` falling back to the first model, explicit version-3 templates, the implicit template when none is declared, and a template overriding the descriptor's fields, with `DescriptorCatalogTests.swift` covering the shipped descriptors.

