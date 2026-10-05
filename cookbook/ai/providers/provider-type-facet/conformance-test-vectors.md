
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| provider-type-facet-001 | config-type-subscription-match, config-type-local-match, config-type-apikey-match | Bucket the Config Type strings `"OAuth Account"`, `"Subscription"`, `"API Key"`, `"Local"`, `"Local Server"` | Returns `subscription`, `subscription`, `apiKey`, `local`, `local` respectively |
| provider-type-facet-002 | config-type-case-insensitive, config-type-subscription-match, config-type-apikey-match, config-type-default-custom | Bucket the Config Type strings `"oauth 2 account"`, `"Access Token"`, `""`, `"Bring your own endpoint"` | Returns `subscription`, `apiKey`, `custom`, `custom` respectively |
| provider-type-facet-003 | config-type-precedence-order, config-type-subscription-match | Bucket the Config Type string `"Subscription Token"` | Returns `subscription`, not `apiKey`, even though the string also contains `"token"` |
| provider-type-facet-004 | matches-empty-selection, matches-membership | Match `apiKey` against an empty selection; match `apiKey` against `{apiKey, local}`; match `subscription` against `{apiKey, local}` | Returns `true`, `true`, `false` respectively |
| provider-type-facet-005 | title-strings, detail-strings | For every facet in the full set of cases | Its title is non-empty and its detail is non-empty, for all four cases |
| provider-type-facet-006 | all-cases-enumeration-order, case-set | Enumerate all cases | Returns `[subscription, apiKey, local, custom]`, in that order |
| provider-type-facet-007 | wire-value-lookup, raw-value-identity | Look up the wire value `"apiKey"`; look up the wire value `"bogus"` | Returns `apiKey` for `"apiKey"`; returns no result for `"bogus"` |
| provider-type-facet-008 | config-type-precedence-order, config-type-local-match, config-type-apikey-match | Bucket the Config Type string `"Local API Key"` | Returns `local` — the local rule is checked and matches before the key/token rule is ever reached |

