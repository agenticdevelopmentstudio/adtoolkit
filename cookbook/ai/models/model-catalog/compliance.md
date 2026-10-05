
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

Notes: graceful-degradation passes because `load(from:)`/`shared` always
resolve to a usable catalog (see `shared-catalog-never-fails-to-exist`).
explicit-error-handling is partial because every decode/load failure is
swallowed via `try?` with no diagnostic signal, unlike the sibling
`AIPluginManager` warning log for an incompatible plugin. data-integrity is
partial because `id`/alias collisions across `Model` entries silently
overwrite in the index with no validation (see
`alias-collision-last-writer-wins`). no-hardcoded-strings fails because
`Model.description` and curated `ModelDetail.goodFor` ship as English-only
prose with no localization mechanism (see Localization).

`separation-of-concerns` passes because `AIModelCatalog` is a decodable data model with lookup, offering and canonical-id resolution only; facet and capability derivation live in `ModelUseFacet` and `ModelCapability`, and loading of plugin bundles belongs to the plugin manager. `unit-test-coverage` is partial: `AIModelCatalogTests.swift` covers canonical-id suffixes, resolution by id, alias and unseen spellings, per-gateway terms, curated details winning, absent fields decoding to empty, the shipped catalog loading and a missing resource yielding an empty catalog, but no test asserts the id and alias collision behavior (last writer wins) or a corrupt catalog being swallowed.

