
| String | Text | Source |
|--------|------|--------|
| missing-key reason | `no "<key>"` | the failure-text renderer |
| type-mismatch reason, named type | `<subject> is not <name>` | the failure-text renderer |
| type-mismatch reason, unnamed type | `<subject> is the wrong kind of value` | the failure-text renderer |
| missing-value reason | `<subject> is null` | the failure-text renderer |
| corrupted-data reason | the underlying decoder's own description text | the failure-text renderer |
| array-shape guard | `expected an array` | the lenient array/dictionary helper |
| object-shape guard | `expected an object` | the lenient array/dictionary helper |
| empty-path subject | `this entry` | the subject resolver |
| non-empty-path subject | `"<path>"` | the subject resolver |
| JSON noun: text | `text` | the JSON-noun lookup |
| JSON noun: boolean | `true or false` | the JSON-noun lookup |
| JSON noun: floating-point number | `a number` | the JSON-noun lookup |
| JSON noun: whole number | `a whole number` | the JSON-noun lookup |
| JSON noun: object | `an object` | the JSON-noun lookup |
| JSON noun: array | `a list` | the JSON-noun lookup |

Every string above is hardcoded English with no lookup table, ICU message,
or locale parameter anywhere in this component — there is no localization
mechanism in this component at all. This is a plain fact about the source,
not a gap: the failure reason is rendered verbatim by a separate,
out-of-scope component (the source's own doc comment names "the settings
panel's Decisions group"), and a port to a platform with an i18n layer MUST
decide, as a design choice outside this contract, whether and how to route
these strings through it.

