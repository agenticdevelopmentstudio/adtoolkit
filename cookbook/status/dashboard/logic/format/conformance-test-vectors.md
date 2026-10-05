
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| format-001 | short-sha-prefix | The short-sha operation on `"abcdef1234567"` | `"abcdef1"` |
| format-002 | short-sha-short-input | The short-sha operation on `"abc"` | `"abc"` |
| format-003 | short-sha-empty-null | The short-sha operation on each of: absent input, and `""` | No result, for each |
| format-004 | short-sha-no-validation | The short-sha operation on `"  zz-not-hex"` | `"  zz-no"` |
| format-005 | first-line-subject | The commit-first-line operation on `"subject\n\nbody text"` | `"subject"` |
| format-006 | first-line-subject, first-line-under-cap | The commit-first-line operation on `"just one line"` | `"just one line"` |
| format-007 | first-line-empty-null | The commit-first-line operation on each of: absent input, and `""` | No result, for each |
| format-008 | first-line-default-max, first-line-cap | The commit-first-line operation on `"x"` repeated 250 times, default max | a string of length 200 |
| format-009 | first-line-cap, first-line-no-ellipsis | The commit-first-line operation on `"x"` repeated 250 times, max 10 | `"xxxxxxxxxx"` — length 10, no ellipsis |
| format-010 | first-line-under-cap | The commit-first-line operation on `"short"`, max 200 | `"short"` |
| format-011 | first-line-lf-only | The commit-first-line operation on `"subject\r\nbody"` | `"subject\r"` |
| format-012 | first-line-empty-subject | The commit-first-line operation on `"\nbody"` | `""` |
| format-013 | plural-singular-at-one, plural-output-shape | The pluralization operation on count 1, noun `"site"` | `"1 site"` |
| format-014 | plural-default-form, plural-plural-otherwise | The pluralization operation on count 3, noun `"site"` | `"3 sites"` |
| format-015 | plural-plural-otherwise | The pluralization operation on count 0, noun `"project"` | `"0 projects"` |
| format-016 | plural-plural-otherwise | The pluralization operation on count -1, noun `"site"` | `"-1 sites"` |
| format-017 | plural-default-form | The pluralization operation on count 2, noun `"person"`, explicit plural `"people"` | `"2 people"` |
| format-018 | plural-number-rendering | The pluralization operation on count 1000, noun `"site"`; and on count 1.5, noun `"site"` | `"1000 sites"`, `"1.5 sites"` |
| format-019 | plural-english-rule | The pluralization operation on count 21, noun `"site"` | `"21 sites"` regardless of runtime locale |
| format-020 | utf16-length | The commit-first-line operation on `"ab😀cd"`, max 3 | a 3-code-unit string: `"ab"` followed by the lone high surrogate of the emoji |
| format-021 | pure-functions, synchronous | Each export, called twice with the same arguments | identical return values; no observable side effect; the result is not a deferred value |

