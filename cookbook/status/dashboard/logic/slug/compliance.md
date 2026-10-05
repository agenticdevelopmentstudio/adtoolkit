
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | partial | Internationalization |

The function is a pure utility kept apart from the two editor components that call
it, so separation of concerns passes. Unit-test coverage fails because no `slug.test.ts`
sits beside `slug.ts`, while most sibling `lib` modules have one. Unicode support is
partial. The function takes any Unicode string without throwing and lower-cases it
with full Unicode rules. But it keeps only ASCII letters and digits, so accented,
non-Latin and emoji characters are dropped, and a wholly non-Latin name produces an
empty slug.

