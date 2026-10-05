
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| whps-001 | round-trip-fidelity, sorted-key-encoding | Construct with `viewType: "markdown.preview", title: "Preview README.md", state: {"scrollTop":420} (as text), options: defaultOptions`, encode, then decode the result | the restored value equals the original |
| whps-002 | absent-state-omits-key | Construct with `viewType: "markdown.preview", title: "Preview", state` absent, `options: defaultOptions`, encode, then decode the result | the restored `state` is absent |
| whps-003 | state-carried-verbatim | Encode then decode a state value of `{"note":"line\nbreak \"quoted\" café"}` | the restored `state` equals that exact string, unchanged |
| whps-004 | state-carried-verbatim | Encode then decode a state value of the literal text `null` (a two-character string, not a JSON null) | the restored `state` equals the string `"null"`, distinct from an absent state |
| whps-005 | unknown-fields-ignored | Decode `{"viewType":"markdown.preview","title":"Preview","iconPath":"a.png"}` | decodes successfully; the restored `viewType` equals `"markdown.preview"` and `title` equals `"Preview"`; the unknown `iconPath` key causes no error |
| whps-006 | missing-view-type-refused | Decode `{"title":"Preview"}` | fails to decode |
| whps-007 | malformed-text-refused | Decode an empty string, the text `not json`, the truncated text `{`, an array `[]`, and the bare string literal `"markdown.preview"` | each fails to decode |
| whps-008 | round-trip-fidelity | Construct with `viewType: "vendor.view-type_2", title: Preview "a"b.md — café, state` absent, `options: defaultOptions`, then encode and decode | the restored value equals the original, including the quote and em-dash in the title |
| whps-009 | missing-options-default-safe, safe-for-concurrent-access | Construct with `options` built from as-declared values with `enableScripts: true, enableForms` absent, `localResourceRoots` absent, then encode and decode | the restored options' `enableScripts` equals `true` and `enableForms` equals `true` |
| whps-010 | round-trip-fidelity | Construct with `options` built from as-declared values with `enableScripts: true, enableForms` absent, `localResourceRoots: []` (an explicit empty-list declaration), then encode and decode | resolving the restored options' local resource roots returns an empty list — the renounced-file-access declaration is not decoded back into the default roots |
| whps-011 | round-trip-fidelity | Construct with `options` built from as-declared values with `localResourceRoots` holding two locations, then encode and decode | resolving the restored options' local resource roots returns exactly those two directories, in the same order |
| whps-012 | missing-options-default-safe | Decode `{"viewType":"markdown.preview","title":"Preview"}` (no `options` key at all) | the restored options' `enableScripts` equals `false`, `enableForms` equals `false`, and resolving local resource roots returns the extension directory followed by the workspace root |
| whps-013 | missing-title-defaults-empty | Decode `{"viewType":"v"}` (no `title` key) | decodes successfully with the restored `title` equal to an empty string |

