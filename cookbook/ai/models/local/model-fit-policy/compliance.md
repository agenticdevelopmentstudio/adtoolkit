
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [test-pyramid](agenticdevelopercookbook://compliance/best-practices#test-pyramid) | passed | Best Practices |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |

Notes: separation-of-concerns passes because the policy is kept at toolkit level specifically so enforcement (`LocalInferenceGuard`) and presentation (`ModelChooserContent`/`ModelChooserViewController`) each consume the same pure computation rather than each reimplementing it, per the Overview's "so every `AIPluginKit` host shares one representation... and the two cannot drift." unit-test-coverage passes because `ModelFitPolicyTests.swift` covers tier boundaries, verdict precedence, and every `fitInfo`/`pickerLabel` text format across 20 vectors. test-pyramid passes because `ModelFitPolicyTests.swift` tests the pure functions entirely at the unit level, with no integration or UI layer needed for a case-less policy enum. no-hardcoded-strings fails because every string `ModelFitPolicy` produces — `gbString`, `footprintDescription`, `fitInfo.text`, `pickerLabel`, and `verdict`'s reasons — is a hardcoded English literal composed inline with no localization key, and that text is shown verbatim by the macOS model picker.

