
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |

`unit-test-coverage` is `partial`: `format.test.ts` gives `commitFullMessage` full
assertion coverage across empty input, newline preservation, trailing-whitespace
stripping, and the `max` cap, but the given source tree contains no dedicated test file
exercising `shortSha` or `commitFirstLine` at all — their behavior in this recipe is
derived from reading `format.ts` directly, not from a passing assertion. `separation-of-
concerns` passes: this file owns exactly one concern, commit-display formatting, and its
own header comment frames its reason for existing as removing that concern from the
fetchers and row builders that used to duplicate it. `explicit-error-handling` passes:
none of the three functions has an error path to swallow — there is no exception handling
and no I/O that could fail — and the `null` each returns for absent or empty input is a
deliberate, documented sentinel value (per the requirements above), not a caught or ignored
failure.

