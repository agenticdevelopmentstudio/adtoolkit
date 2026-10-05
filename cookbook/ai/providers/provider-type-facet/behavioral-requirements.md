
- **case-set**: The facet MUST define exactly four cases: `subscription`, `apiKey`, `local`, and `custom`.
- **raw-value-identity**: Each case's wire (string) value MUST equal its case name exactly (`"subscription"`, `"apiKey"`, `"local"`, `"custom"`).
- **all-cases-enumeration-order**: The facet MUST support enumerating all four cases, and that enumeration MUST list them in declaration order: `subscription`, `apiKey`, `local`, `custom`.
- **safe-to-share**: The facet MUST be safe to share across concurrent contexts with no synchronization; because it is a case-only value with a string wire form and no associated data, every instance is trivially shareable.
- **json-round-trip**: The facet MUST support encoding to and decoding from JSON via its wire value; encoding an instance MUST produce its wire-value string, and decoding MUST succeed only when the JSON string equals one of the four wire values.
- **value-equality-and-hashing**: The facet MUST support equality comparison and hashing derived from its case identity alone (it carries no associated data), since callers place instances into a set (the matching function's selection parameter and the picker's persisted type-filter selection).
- **wire-value-lookup**: The facet MUST provide a lookup from a wire-value string back to its case, returning the matching case for one of the four wire values and no result for any other string.
- **title-strings**: The title lookup MUST return `"Subscription"` for `subscription`, `"API key"` for `apiKey`, `"Local LLM"` for `local`, and `"Custom"` for `custom`.
- **detail-strings**: The detail lookup MUST return `"Uses an account you already have"` for `subscription`, `"Needs a key from the vendor"` for `apiKey`, `"Runs on this machine"` for `local`, and `"An endpoint you configure yourself"` for `custom`.
- **config-type-case-insensitive**: Bucketing a Config Type string MUST lowercase it before testing it against any rule, so bucketing is case-insensitive.
- **config-type-subscription-match**: Bucketing MUST resolve to `subscription` when the lowercased string contains `"oauth"`, `"subscription"`, or `"account"`.
- **config-type-local-match**: When the lowercased string does not satisfy the subscription rule, bucketing MUST resolve to `local` when it contains `"local"`.
- **config-type-apikey-match**: When the lowercased string satisfies neither the subscription nor the local rule, bucketing MUST resolve to `apiKey` when it contains `"key"` or `"token"`.
- **config-type-default-custom**: Bucketing MUST resolve to `custom` when the lowercased string satisfies none of the subscription, local, or key/token rules — including the empty string.
- **config-type-precedence-order**: When a string satisfies more than one rule (for example a string containing both `"account"` and `"token"`, or both `"local"` and `"key"`), bucketing MUST resolve to the first rule that matches in the fixed order subscription, then local, then apiKey, then custom; a later rule MUST NOT be evaluated once an earlier one has matched.
- **matches-empty-selection**: The matching function MUST return `true` for every facet when the selection is empty.
- **matches-membership**: The matching function MUST return whether the facet is a member of the selection when the selection is non-empty.

