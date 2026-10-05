
| Check | Status | Category |
|-------|--------|----------|
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |

This status rests on `Badge.swift`: `contrastingTextColor(on:)` uses an
unverified perceptual-luminance heuristic rather than a WCAG contrast-ratio
computation, so a specific minimum ratio cannot be confirmed from the source
alone (`contrast-ratio`).

`separation-of-concerns` passes because `Badge.swift` owns only the pill shape, padding and text styling and takes its text, color and style from the caller rather than deriving them from a status vocabulary of its own. `unit-test-coverage` is `failed`: a search of the Apple test targets finds no test file for `Badge`, so vectors badge-001 through badge-016 are unpinned by automated tests.

