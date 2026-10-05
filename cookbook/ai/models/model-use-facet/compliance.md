
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [test-pyramid](agenticdevelopercookbook://compliance/best-practices#test-pyramid) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

Notes: separation-of-concerns passes because the source itself distinguishes
"the pure core" (`facets(text:capabilities:)`) from the `AIModelCatalog`-aware
convenience wrapper (`facets(for:extraText:)`), and keeps filtering
(`matches`) as a third, independent function. graceful-degradation passes
because an evidence-free model always passes `matches(...)` rather than being
hidden (see `filter-unknown-model-passes`). test-pyramid passes because
`ModelUseFacetTests.swift` exercises the pure derivation and filter logic
directly, with no UI, network, or file-system dependency in the test suite.
no-hardcoded-strings fails because `title` and `detail` return English-only
`String` literals with no localization mechanism (see Localization).

`unit-test-coverage` passes because `ModelUseFacetTests.swift` covers facet derivation from description prose, word-prefix anchoring, phrase evidence, capabilities implying facets, the any-of filter semantics, an empty selection filtering nothing, an evidence-free model always passing, and every facet having a title and tooltip.

