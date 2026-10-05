
- **empty-value-refused**: the safety check MUST return false when the value
  is the empty string.
- **leading-dot-refused**: the safety check MUST return false when the first
  character of the value is `.`, regardless of what follows — this covers a
  bare `.`, `..`, and any name beginning with a hidden-file dot such as
  `.hidden`.
- **forward-slash-refused**: the safety check MUST return false when the
  value contains a `/` character anywhere in the string, including as the
  first, last, or only character.
- **backslash-refused**: the safety check MUST return false when the value
  contains a `\` character anywhere in the string.
- **colon-refused**: the safety check MUST return false when the value
  contains a `:` character anywhere in the string.
- **control-character-refused**: the safety check MUST return false when the
  value contains any Unicode scalar whose value is less than `U+0020`, or
  that is exactly `U+007F`, anywhere in the string.
- **c0-boundary-accepted**: the safety check MUST return true for a value
  containing `U+0020` (space) or `U+007E` (`~`) — the scalars immediately
  outside the refused C0/DEL range — provided no other refusal rule applies.
- **c1-range-accepted**: the safety check MUST return true for a value
  containing a scalar in the `U+0080`–`U+009F` C1 control range, provided no
  other refusal rule applies; the denylist stops at `U+007F` and does not
  extend into C1.
- **interior-dot-accepted**: the safety check MUST return true for a value
  whose only `.` characters occur after the first character, such as an
  interior dot in an identifier (`ms-python.python`) or a version string
  (`2024.1.0-rc.1`).
- **non-ascii-accepted**: the safety check MUST return true for a value
  composed of non-ASCII characters (for example Japanese, Cyrillic, accented
  Latin, or emoji) that contains none of the refused characters; the check
  is a denylist of shapes, not an allowlist of characters.
- **literal-percent-sequence-accepted**: the safety check MUST return true
  for a value containing a literal percent-encoded sequence such as `%2F` or
  `%2E%2E`, because the check inspects the literal scalars of the value and
  performs no percent-decoding.
- **pure-function**: the safety check MUST compute its result solely from
  the scalars of the value, MUST NOT mutate the value or any external state,
  and MUST NOT perform file, network, or other I/O.
- **synchronous-non-throwing**: the safety check MUST return synchronously,
  MUST NOT report failure through an error or an absent result, and MUST
  always return a plain true/false result.
- **callable-from-any-thread**: the safety check MUST be callable
  synchronously from any thread or concurrency context without additional
  synchronization, because it is a stateless computation operating only on
  its input string and boolean result.

