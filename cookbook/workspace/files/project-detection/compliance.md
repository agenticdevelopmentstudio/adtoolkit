
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [fault-tolerance](agenticdevelopercookbook://compliance/reliability#fault-tolerance) | passed | Reliability |

Notes: unit-test-coverage is partial because `LanguageDetectionTests.swift`
covers `LanguageDetection.language(for:)`'s built-in and custom-override
paths (three tests) but not `lspLanguageId(for:)`, while `IDEDetector.swift`
— `IDEType`, `IDEProject`, and every function on `IDEDetector` — has no
test file anywhere in the repository (only compiled build artifacts were
found, no source test). separation-of-concerns passes because
`IDEDetector.swift` and `LanguageDetection.swift` are two independently
named files under `.../Model/Detection/`, each with one detection
responsibility, and `LanguageDetection` itself keeps "consult the user's
override" and "fall back to the built-in table" as two distinct steps
rather than one entangled one. no-hardcoded-strings fails because
`IDEType.displayName`/`systemImageName` and the `"VS Code"` literal are
English-only literals with no localization mechanism (see Localization).
fault-tolerance passes because every file-system read in `scan`,
`matchMarkers`, and `detectJetBrainsType` is wrapped in `try?`, so an
unreadable directory or unexpected entry degrades to an empty or partial
result rather than throwing or crashing (see Edge Cases).

