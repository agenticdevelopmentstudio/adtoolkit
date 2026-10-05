
**Decision**: AND the tokens together rather than OR them.
**Rationale**: Each extra word narrows the activity feed, so an operator can type `testing failed` to find failed runs on the testing environment (filter-005). An OR rule would widen the result with each word.
**Approved**: pending

**Decision**: Match plain substrings anywhere rather than whole words or prefixes.
**Rationale**: Row search text contains dotted names such as `staging.adh` and `testing.admin.adh`. Substring matching lets `adh` or `admin` hit inside those names without a tokenizer that knows about dots (filter-003, filter-011).
**Approved**: pending

**Decision**: A blank query matches everything.
**Rationale**: The doc comment declares it, and it makes an empty search box a no-op, so clearing the box restores the unfiltered feed.
**Approved**: pending

**Decision**: Use `includes` and `toLowerCase`, not a regular expression or a locale-aware collator. (React/Web implementation — `includes` and `toLowerCase` are this module's own choice of JavaScript API.)
**Rationale**: Literal substring matching means user input can never be read as a pattern or throw on metacharacters (filter-019). Locale-independent lowercasing gives the same result in every browser locale. The cost is no Unicode normalization and no locale-specific case folding, which the edge cases record.
**Approved**: pending

