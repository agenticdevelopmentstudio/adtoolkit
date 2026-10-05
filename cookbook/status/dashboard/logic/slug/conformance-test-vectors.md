
This logic has no reference test suite for these vectors (see Platform Notes). Every vector below follows from the four chained steps in the slug function.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| slug-001 | lowercase-first, hyphenate-runs | the slug function called with `"Production Sites"` | `"production-sites"` |
| slug-002 | trim, trim-hyphens | the slug function called with `"  Hello World  "` | `"hello-world"` |
| slug-003 | hyphenate-runs, no-double-hyphen | the slug function called with `"a -- b__c"` | `"a-b-c"` |
| slug-004 | hyphenate-runs, shared-form | the slug function called with `"status.example.com"` | `"status-example-com"` |
| slug-005 | trim-hyphens | the slug function called with `"--Edge!!"` | `"edge"` |
| slug-006 | ascii-only-alphabet | the slug function called with `"Café Menu"` | `"caf-menu"` |
| slug-007 | empty-allowed, total | the slug function called with `""`, `"   "`, `"---"`, `"日本"` | `""` each, no exception |
| slug-008 | idempotent | the slug function called on its own result for `"My Group #1"` | `"my-group-1"`, the same as calling it once on `"My Group #1"` |
| slug-009 | no-uniqueness | the slug function called with `"A B"`, `"a-b"`, `"a_b"` | `"a-b"` each |
| slug-010 | ascii-only-alphabet | the slug function called with `"Server 42"` | `"server-42"`, digits kept |
| slug-011 | signature, pure | call the slug function with `"x"` twice | `"x"` both times, returned synchronously, nothing else observable changes |

