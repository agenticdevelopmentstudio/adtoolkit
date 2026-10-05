
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| T1 | renders-single-command-palette | mount with the picker open | Exactly one command-palette instance renders, receiving the open state, an open-state change callback, the query text, a query-change callback, one result group, an accessible label, a placeholder, a loading flag, an error message, and an empty-results label |
| T2 | resets-on-close | type "abc", let it resolve, then close the picker | The command palette receives an empty query text, an empty result group, no error message, and loading false |
| T3 | skips-search-for-empty-query | open with an empty query (also: a whitespace-only query) | search not called; the command palette receives an empty result group, loading false, no error message |
| T4 | sets-loading-before-debounce-elapses | type "a"; inspect the state passed to the command palette before the debounce delay elapses | The command palette receives loading true |
| T5 | debounces-search-call | type "a", "ab", "abc" within the debounce delay, then wait past it | search called exactly once, with "abc" |
| T6 | debounces-search-call | type "  abc " (leading and trailing whitespace) as the final value within the debounce delay, then wait past it | search called exactly once, with "abc" (trimmed), never "  abc " |
| T7 | aborts-superseded-search | type "ab"; before the debounce delay elapses, type "abc" | the "ab" debounce timer is cleared and never invokes search; search is ultimately invoked once, for "abc" |
| T8 | aborts-superseded-search | type "ab"; wait until its debounced call invokes search but before it settles; then type "abc" | the "ab" call is canceled |
| T9 | ignores-aborted-search-results | resolve the canceled "ab" call's result after "abc" is in flight | the loading flag, error message, and result group passed to the command palette are unaffected by the "ab" settlement |
| T10 | populates-options-on-success | search resolves with one option `{rdid:"r1",entityType:"ecosystem",entityId:"e1"}` | The command palette receives a result group containing one item with identifier "r1", label "r1", badge "ecosystem"; no error message; loading false |
| T11 | surfaces-search-rejection | search rejects with an error object carrying the message "boom" | The command palette receives error message "boom"; the result group is empty; loading false |
| T12 | surfaces-search-rejection | search rejects with a non-error-object value | The command palette receives error message "Search failed" |
| T13 | calls-latest-search-implementation | re-render with a new search function, query text unchanged, then let the pending call fire | the most recently supplied search function is the one invoked |
| T14 | passes-full-option-to-onPick | select the result `{rdid:"r1",entityType:"ecosystem",entityId:"e1"}` | the pick callback is called with that whole option |
| T15 | closes-on-pick | select any result | the open-state change callback is called to close the picker (fired by the composed command palette's own commit action) before/independent of the pick callback handling |
| T16 | labels-group-by-entity-type | entity type label "ecosystem" | group label reads "ecosystem addresses" |
| T17 | labels-group-by-entity-type | no entity type label | group label reads "Addresses" |
| T18 | derives-default-placeholder | entity type label "ecosystem", no placeholder | placeholder reads "Search ecosystem addresses…" |
| T19 | derives-default-placeholder | no entity type label, no placeholder | placeholder reads "Search addresses…" |
| T20 | derives-empty-label-from-query | empty query | empty-results label reads "Start typing an address" |
| T21 | derives-empty-label-from-query | non-empty query, zero results | empty-results label reads "No matching address" |
| T22 | defaults-title-and-aria-label | no title given | the command palette receives accessible label "Choose an address" |
| T23 | renders-each-result-by-rdid-with-badge | option `{rdid:"r1",entityType:"ecosystem",entityId:"e1"}` | rendered item identifier is "r1", label is "r1", badge is "ecosystem" |
| T24 | aborts-superseded-search, resets-on-close | open, type "ab", close before the debounce delay elapses, then reopen before the debounce delay (measured from the "ab" keystroke) elapses | search is never called with "ab"; no stale call from the first session reaches search in the reopened session |

