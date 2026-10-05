
- **Absent and empty input**: The short-sha and commit-first-line operations MUST return no result for an absent value and for `""` (format-003, format-007). The pluralization operation with an empty singular noun MUST return the number, a space, and `"s"` for a count other than 1 (an empty noun of `"0"` yields `"0 s"`) or the number and a trailing space for a count of exactly 1.
- **Whitespace-only input**: A hash or message consisting only of spaces is non-empty and MUST be processed, not treated as missing: the short-sha operation on `"   "` returns `"   "`.
- **Boundary at exactly 7 and exactly the maximum length**: A 7-character hash MUST be returned unchanged; a subject whose length equals the maximum MUST be returned unchanged, because the cap applies only when the length is strictly greater than the maximum.
- **Maximum length of zero**: The commit-first-line operation on `"abc"` with max 0 MUST return `""`.
- **Negative maximum length**: The operation does not validate the maximum. With a negative maximum the length test is always true and the slice counts from the end, so the commit-first-line operation on `"abcdef"` with max -2 MUST return `"abcd"` (the last two characters dropped). No caller in the package passes a maximum; the default 200 is the only value used.
- **Not-a-number maximum length**: A length compared with a not-a-number value is never greater, so the commit-first-line operation with such a maximum MUST return the whole first line uncapped.
- **Non-integer count in pluralization**: The pluralization operation on `1.0` MUST return `"1 site"` (1.0 equals 1); on a not-a-number count it MUST return `"NaN sites"`.
- **Surrogate pairs**: Truncation counts UTF-16 code units and MAY split a surrogate pair at the cap (format-020); commit hashes are ASCII, so the short-sha operation is unaffected in practice.
- **Windows line endings**: A CRLF message MUST keep the trailing carriage return on the subject (format-011).
- **Concurrent access**: Not applicable — the operations are pure, synchronous and stateless, so concurrent callers cannot observe each other.
- **Error states**: Not applicable — the operations touch no file, network or other dependency and cannot fail for inputs of their declared shapes.
- **Offline or disconnected state**: Not applicable — no network is involved.

