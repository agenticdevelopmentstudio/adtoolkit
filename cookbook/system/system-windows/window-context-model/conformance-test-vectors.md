
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wmcsw-001 | strategy-cases, strategy-value-list | The complete list of match-strategy values | `appAndTitleExact`, `appAndTitleSubstring`, `appAndTitleRegex`, `appOnly`, in that order; count 4 |
| wmcsw-002 | strategy-raw-values | Encode the match-strategy value `appOnly` to JSON; decode the JSON string `"appAndTitleRegex"` | `"appOnly"`; the `appAndTitleRegex` value |
| wmcsw-003 | strategy-unknown-raw | Decode the JSON string `"fuzzy"` as a match-strategy value; construct a match-strategy value from the raw string `"fuzzy"` | Fails with a data-corrupted decoding error; no value |
| wmcsw-004 | display-name-exact, display-name-substring, display-name-regex, display-name-app-only | The display name of each match-strategy value, in declaration order | `"Exact"`, `"Substring"`, `"Regex"`, `"App Only"` |
| wmcsw-005 | fingerprint-init-verbatim, fingerprint-fields | Construct a window fingerprint with `app: "Xcode"`, `titlePattern: " Proj "`, `matchStrategy: appAndTitleExact`, `display: 2` | `app` is `"Xcode"`, `titlePattern` is `" Proj "` (untrimmed), `matchStrategy` is `appAndTitleExact`, `display` is `2` |
| wmcsw-006 | regex-not-validated, strategy-semantics-declared | Fingerprint with `titlePattern: "JIRA-\\d+"`, `appAndTitleRegex`; score against window app `"TestApp"`, title `"JIRA-1234 details"`, different display | Fingerprint constructs; the window matcher's score returns 80 |
| wmcsw-007 | regex-not-validated | Fingerprint with `titlePattern: "("`, `appAndTitleRegex` | Fingerprint constructs without error; the matcher scores it 0 and logs the compile error |
| wmcsw-008 | display-tie-breaker | Fingerprint `appOnly`, app `"Terminal"`, `display: 7`; window app `"Terminal"`, `display: 7` | The window matcher's score returns 90 (80 + 10 display bonus) |
| wmcsw-009 | with-title-copy, with-title-non-mutating | A window info value with `id: 5`, `app: "Mail"`, `pid: 42`, `title: ""`, `frame: [[1,2],[3,4]]`, `display: 1`, `isOnScreen: true`, `layer: 0`; back-fill its title with `"Inbox"` | The result's `title` is `"Inbox"`; its `id`, `pid`, `frame`, `display`, `isOnScreen` and `layer` equal the original's; the original's `title` remains `""` |
| wmcsw-010 | info-identity, value-equality | The window info value from wmcsw-009 and its title-backfilled copy with `"x"` | Same `id`; the two values are not equal |
| wmcsw-011 | snapshot-id-default, snapshot-window-id-default, snapshot-is-live | Construct a window snapshot with `fingerprint: fp`, `savedFrame` zero, `display: 0`, `app: "Mail"`, `title: ""`, twice | Two different `id` values; `windowID` absent; live flag `false` |
| wmcsw-012 | snapshot-is-live | Snapshot with `windowID: 9`; then set `windowID` to absent | Live flag `true`, then `false` |
| wmcsw-013 | snapshot-display-independent | Snapshot with fingerprint `display` `1`, snapshot `display: 1`; set snapshot `display = 3` | Snapshot `display` is `3`; fingerprint `display` remains `1` |
| wmcsw-014 | context-init-defaults | Construct a window context with `name: "Docs"` | `color` is `"#007AFF"`, `windowSnapshots` is empty, `lastFocusedWindowID` is absent, `createdAt` within 1 s of now, a present `id` |
| wmcsw-015 | add-window-append | Empty context; add snapshot `a`, then add snapshot `b` (distinct `id`s) | `windowSnapshots`' ids, in order, are `[a.id, b.id]` |
| wmcsw-016 | add-window-replace, add-window-keeps-focus | Context `[a, b]`, `lastFocusedWindowID` is `a.id`; add an updated snapshot `a'` whose `id` equals `a.id` and whose `title` is `"new"` | Count 2, order `[a', b]`, first snapshot's `title` is `"new"`, `lastFocusedWindowID` remains `a.id` |
| wmcsw-017 | add-window-no-window-id-dedupe | Empty context; add `a` and `b` with distinct `id`s, both `windowID: 7` | Count 2 |
| wmcsw-018 | remove-by-id, remove-by-id-clears-focus | Context `[a, b]`, `lastFocusedWindowID` is `a.id`; remove the snapshot with `id: a.id` | Returns `a`; `windowSnapshots` is `[b]`; `lastFocusedWindowID` is absent |
| wmcsw-019 | remove-by-id-missing | Context `[a]`, `lastFocusedWindowID` is `a.id`; remove the snapshot with a freshly generated `id` not in the context | Returns no value; context unchanged |
| wmcsw-020 | remove-by-id-clears-focus | Context `[a, b]`, `lastFocusedWindowID` is `b.id`; remove the snapshot with `id: a.id` | `lastFocusedWindowID` remains `b.id` |
| wmcsw-021 | remove-by-window-id, remove-by-window-id-clears-focus | Context `[a (windowID 7), b (windowID 7)]`, `lastFocusedWindowID` is `a.id`; remove the snapshot with `windowID: 7` | Returns `a`; `windowSnapshots` is `[b]`; `lastFocusedWindowID` is absent |
| wmcsw-022 | remove-by-window-id-missing | Context `[a (windowID absent)]`; remove the snapshot with `windowID: 0` | Returns no value; context unchanged |
| wmcsw-023 | snapshot-lookup | Context `[a, b]`; look up the snapshot with `id: b.id`; look up the snapshot with a freshly generated `id` not in the context | `b`; no value |
| wmcsw-024 | update-by-id, update-scope | Context `[a]`; update the snapshot with `id: a.id`, setting `title` to `"T"` and `windowID` to `3` | Returns `true`; the updated snapshot's `title` is `"T"`, `windowID` is `3`, `id` remains `a.id` |
| wmcsw-025 | update-by-id-missing | Context `[a]`; update the snapshot with a freshly generated `id` not in the context, recording whether the update ran | Returns `false`; the update never ran |
| wmcsw-026 | update-by-window-id | Context `[a (windowID 4)]`; update the snapshot with `windowID: 4`, setting `savedFrame` to `[[0,0],[10,10]]`; then update the snapshot with `windowID: 5` | First returns `true` with the frame updated; second returns `false` |
| wmcsw-027 | live-window-count | Context with snapshots whose `windowID`s are `1`, absent, `2` | Live-window count is `2` |
| wmcsw-028 | serializable-by-field-name, optional-omitted, computed-not-encoded | Encode a snapshot whose `windowID` is absent, with keys in sorted order | Keys are `app`, `display`, `fingerprint`, `id`, `lastSeen`, `savedFrame`, `title`; no `windowID` key and no live-flag key |
| wmcsw-029 | frame-encoding | Encode a window info value whose frame has origin `(1, 2)` and size `(3, 4)` | `"frame":[[1,2],[3,4]]` |
| wmcsw-030 | missing-key-throws | Decode a window fingerprint from `{"app":"Xcode","titlePattern":"P","matchStrategy":"appOnly"}` | Fails with a key-not-found decoding error for `display` |
| wmcsw-031 | serializable-by-field-name, value-equality | Encode then decode a window context with two snapshots, using the same date format both ways | Decoded value equals the original (dates at a precision the format preserves) |
| wmcsw-032 | no-side-effects, no-errors | Call every public operation of the five types | None throws; no file, network, log or process activity |

