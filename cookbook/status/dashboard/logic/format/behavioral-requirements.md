
### Pluralization operation

- **plural-signature**: The module MUST export the pluralization operation, accepting a count, a singular noun, and an optional explicit plural noun, and returning a text value.
- **plural-default-form**: When the plural noun is omitted, the operation MUST use the singular noun with the letter `s` appended as the plural form.
- **plural-singular-at-one**: When the count is strictly equal to `1`, the operation MUST use the singular noun.
- **plural-plural-otherwise**: When the count is any value other than `1` (including `0`, negatives, fractions and a not-a-number value), the operation MUST use the plural form as the noun.
- **plural-output-shape**: The operation MUST return the number, one space, then the noun, with no other characters.
- **plural-number-rendering**: The operation MUST render the count with the platform's default number-to-text conversion (no digit grouping, no locale decimal separator, no rounding), so `1000` renders as `1000` and `1.5` as `1.5`.
- **plural-english-rule**: The operation MUST apply only the two-form English rule (one versus other); it MUST NOT consult a locale or plural-category rules.

### Short-sha operation

- **short-sha-signature**: The module MUST export the short-sha operation, accepting a text value that may be absent, and returning a text value or no result.
- **short-sha-empty-null**: The operation MUST return no result when the input is absent or the empty string.
- **short-sha-prefix**: For a non-empty input, the operation MUST return its first 7 characters.
- **short-sha-short-input**: For a non-empty input of 7 or fewer characters, the operation MUST return it unchanged.
- **short-sha-no-validation**: The operation MUST NOT validate that the input is hexadecimal or trim whitespace; any non-empty text is truncated as-is.

### Commit-first-line operation

- **first-line-signature**: The module MUST export the commit-first-line operation, accepting a text value that may be absent and an optional maximum length, and returning a text value or no result.
- **first-line-default-max**: When the maximum length is omitted, the operation MUST use `200`.
- **first-line-empty-null**: The operation MUST return no result when the message is absent or the empty string.
- **first-line-subject**: For a non-empty message, the operation MUST return the text before the first line-feed character, or the whole message when it contains none.
- **first-line-lf-only**: The operation MUST split only on the line-feed character; a carriage return before the line feed MUST remain at the end of the returned subject.
- **first-line-empty-subject**: When the message is non-empty but begins with a line feed, the operation MUST return the empty string, not no result.
- **first-line-cap**: When the subject is longer than the maximum length, the operation MUST return exactly its first `max` characters.
- **first-line-no-ellipsis**: A capped subject MUST NOT carry an ellipsis or any other truncation indicator.
- **first-line-under-cap**: When the subject is at the maximum length or shorter, the operation MUST return it unchanged.

### Module-wide

- **utf16-length**: Character counts in the short-sha and commit-first-line operations MUST be UTF-16 code units, not grapheme clusters or code points.
- **pure-functions**: Every export MUST be a pure function: it MUST NOT read or write shared state, perform I/O, or throw for any input matching its declared shape.
- **synchronous**: Every export MUST return synchronously; there is no async work, caching or cancellation to order.

