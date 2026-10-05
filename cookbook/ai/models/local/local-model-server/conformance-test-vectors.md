
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| LMS-001 | is-loopback-host-extraction, is-loopback-case-insensitive-compare, is-loopback-membership-result | Check loopback for base URL `http://localhost:11434/v1` and for `http://127.0.0.1:11434/v1` | Both return true |
| LMS-002 | is-loopback-membership-result | Check loopback for base URL `https://api.anthropic.com/v1` | Returns false |
| LMS-003 | is-loopback-unparseable-false | Check loopback for an empty base URL | Returns false |
| LMS-004 | is-loopback-unparseable-false | Check loopback for base URL `localhost:11434` (no scheme prefix) | Returns false; without a scheme and authority marker, no host can be determined |
| LMS-005 | native-tags-url-strip-v1-suffix, native-tags-url-append-and-construct | Derive the native tags URL for base URL `http://localhost:11434/v1` | Result is `http://localhost:11434/api/tags` |
| LMS-006 | native-tags-url-strip-trailing-slashes-first-pass, native-tags-url-strip-v1-suffix, native-tags-url-strip-trailing-slashes-second-pass | Derive the native tags URL for base URL `http://localhost:11434/v1/` | Result is `http://localhost:11434/api/tags` |
| LMS-007 | native-tags-url-append-and-construct | Derive the native tags URL for base URL `http://localhost:11434` (no `/v1` suffix at all) | Result is `http://localhost:11434/api/tags` |
| LMS-008 | native-tags-url-whitespace-trim, native-tags-url-empty-yields-nil | Derive the native tags URL for an empty base URL | Returns nothing |
| LMS-009 | native-tags-url-strip-v1-suffix | Derive the native tags URL for base URL `http://localhost:11434/V1` (uppercase suffix) | Result is `http://localhost:11434/api/tags`, because the suffix comparison is case-insensitive |
| LMS-010 | parse-sizes-dual-key-indexing, parse-sizes-missing-size-excluded, size-of-exact-match, size-of-latest-fallback | Parse the response body `{"models":[{"name":"llama3.1:8b","model":"llama3.1:8b","size":4920000000},{"name":"qwen3-coder-next:latest","size":51000000000},{"name":"broken-no-size"}]}`, then resolve the size for model `qwen3-coder-next` and for `llama3.1:8b` | The parsed sizes are `llama3.1:8b -> 4_920_000_000`, `qwen3-coder-next:latest -> 51_000_000_000`; `broken-no-size` is excluded (no size). Resolving `qwen3-coder-next` returns `51_000_000_000` (via the `:latest` fallback); resolving `llama3.1:8b` returns `4_920_000_000` (exact match) |
| LMS-011 | parse-sizes-whole-decode-failure-empty | Parse the response body `not json` | Returns an empty map |
| LMS-012 | parse-sizes-per-element-tolerance | Parse a response with three entries where the middle one has wrong-typed `name`/`size` fields and the other two are well-formed | Returns a map with exactly the two well-formed entries; the middle entry is dropped without discarding the other two |
| LMS-013 | size-of-total-miss-nil | Resolve the size for model `nonexistent` against an empty map | Returns nothing |
| LMS-014 | parse-sizes-neither-key-excluded | Parse the response body `{"models":[{"size":100}]}` (an entry with `size` but neither `name` nor `model`) | Returns an empty map |
| LMS-015 | parse-sizes-array-order-last-write-wins | Parse the response body `{"models":[{"name":"m","size":1},{"model":"m","size":2}]}` (two distinct entries whose `name`/`model` fields collide on the same string `m`) | Returns `{"m": 2}` — the later entry's value overwrites the earlier one under the shared key |

