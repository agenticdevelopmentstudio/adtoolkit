
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-credential-kind-001 | two-kinds, raw-value-stable | Read the raw values of the OAuth kind and the long-lived kind. | `oauth` and `long-lived`. |
| claude-credential-kind-002 | title-per-kind | Read the title of each kind. | `OAuth` and `Long-lived`. |
| claude-credential-kind-003 | key-spelling | Build the key for account `alice@example.com` under the OAuth kind. | `oauth:alice@example.com`. |
| claude-credential-kind-004 | key-spelling | Build the key for the same account under the long-lived kind. | `long-lived:alice@example.com`, distinct from the OAuth key. |
| claude-credential-kind-005 | key-from-raw-value | Build a key from account `alice@example.com` with raw kind absent, then with raw kind empty. | Both return `alice@example.com`. |
| claude-credential-kind-006 | key-from-raw-value | Build a key from raw kind `future-kind` and account `alice@example.com`. | `future-kind:alice@example.com`. |
| claude-credential-kind-007 | parse-inverse | Parse `oauth:alice@example.com`. | Kind OAuth, name `alice@example.com`. |
| claude-credential-kind-008 | parse-inverse | Parse `alice@example.com` (legacy) and `future-kind:alice@example.com`. | Both return nothing. |
| claude-credential-kind-009 | account-names-keep-colons-after-first | Parse `long-lived:team:alice`. | Kind long-lived, name `team:alice`. |

