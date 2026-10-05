
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | partial | Privacy and Data |

`separation-of-concerns` passes because `AIChatContext.swift` performs no
I/O, storage, or transport of its own — per its own doc comments, the host
resolves and injects configuration, `AIPlugin.buildRequest(_:)` translates
the context into a request, and this file is only the data shape shared
between them. `data-minimization` is `partial`: `AIPluginConfig.values`
carries the plugin's *entire* resolved field set — including a credential,
when the template declares one — as a single undifferentiated dictionary
passed into `AIChatContext`, with no narrower, credential-free view
available to a caller that only needs `model` or `baseURL`, and no
redaction safeguard on the type's default description (see the Privacy
section).

`unit-test-coverage` is partial: no test file targets `AIChatContext.swift` itself, but the type is constructed as the input of `PluginRequestTests.swift` (request building for each provider plugin) and `PluginTransportTests.swift` / `PluginTransportFramingTests.swift`, so its field shape is exercised indirectly while its defaults and equality are never asserted on their own.

