
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | best-practices |

**Separation of concerns.** The module only maps a `Row` to display fields and serializes them. Platform labels come from `deploy-display.ts`, host parsing comes from `url.ts`, and rendering and the clipboard write belong to the calling components.

**Unit test coverage.** `row-detail.test.ts` exercises both exports: the deploy and endpoint mappings, resolved rows, problem de-duplication, the diagnostics, the `since` fallback, error text, every settled and unsettled deploy outcome including the Crunchy carve-out, and the serializer's populated-only, link and error-block behavior. The GlitchTip carve-out, the `url` line and the empty-string fallbacks are not asserted directly.

**Explicit error handling.** The only failure path is URL parsing inside `hostOf`, which falls back to the raw input by design. Every other input maps to a defined value.

**Good test properties.** The tests build rows from one `row()` helper with explicit overrides, assert observable fields, and depend on no clock, network or shared state.

