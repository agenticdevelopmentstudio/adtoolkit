
### shortSha

- **short-sha-truncation**: `shortSha(hash)` MUST return `hash.slice(0, 7)` when `hash` is
  a non-empty string — the first 7 characters, GitHub's short-sha form.
- **short-sha-null-on-falsy**: `shortSha(hash)` MUST return `null` when `hash` is `null`,
  `undefined`, or the empty string `''`, since the function's guard is the JavaScript
  truthiness of `hash`, not an explicit `=== null || === undefined` check.
- **short-sha-no-validation**: `shortSha` MUST NOT validate `hash`'s length or character
  set before truncating; a `hash` shorter than 7 characters is returned unchanged (via
  `String.prototype.slice`, which does not pad or throw on an out-of-range end index), and
  a `hash` containing non-hexadecimal characters is truncated identically to a valid sha.

### commitFirstLine

- **commit-first-line-extraction**: `commitFirstLine(message, max)` MUST return the
  substring of `message` up to (and not including) the first `"\n"` character, obtained via
  `message.split("\n")[0]`.
- **commit-first-line-null-on-falsy**: `commitFirstLine(message, max)` MUST return `null`
  when `message` is `null`, `undefined`, or the empty string `''`.
- **commit-first-line-no-trim**: `commitFirstLine` MUST NOT trim leading or trailing
  whitespace from the extracted first line; a message whose first line is
  `"  leading and trailing  "` with no embedded `"\n"` is returned with that whitespace
  intact.
- **commit-first-line-cap**: `commitFirstLine` MUST truncate the extracted first line to
  `max` characters, via `first.slice(0, max)`, when the first line's length exceeds `max`;
  a first line whose length is exactly `max` or fewer MUST be returned unchanged.
- **commit-first-line-default-max**: `commitFirstLine` MUST default `max` to `200` when the
  caller supplies no second argument.

### commitFullMessage

- **commit-full-message-preserve-newlines**: `commitFullMessage(message, max)` MUST return
  the message with internal newlines intact — unlike `commitFirstLine`, it MUST NOT split
  on or discard anything after the first `"\n"`; the doc comment states this directly: it
  "KEEPS newlines so the details pane can show the whole 'git comment'".
- **commit-full-message-null-on-falsy**: `commitFullMessage(message, max)` MUST return
  `null` when `message` is `null`, `undefined`, or the empty string `''`.
- **commit-full-message-trailing-trim**: `commitFullMessage` MUST strip only trailing
  whitespace from `message`, via `message.replace(/\s+$/, "")` — leading and internal
  whitespace (including internal newlines) MUST be left unmodified.
- **commit-full-message-empty-after-trim**: `commitFullMessage` MUST return `null` when
  `message` consists entirely of whitespace, since stripping trailing whitespace from an
  all-whitespace string leaves the empty string, which the function then treats as absent.
- **commit-full-message-cap**: `commitFullMessage` MUST truncate the trimmed message to
  `max` characters, via `trimmed.slice(0, max)`, when its length exceeds `max`; a trimmed
  message whose length is exactly `max` or fewer MUST be returned unchanged.
- **commit-full-message-default-max**: `commitFullMessage` MUST default `max` to `4000`
  when the caller supplies no second argument.

### Purity and Side Effects

- **pure-synchronous**: `shortSha`, `commitFirstLine`, and `commitFullMessage` MUST each
  execute synchronously and MUST perform no I/O, network call, logging, or persistence of
  any kind; each is a pure function of its arguments with no dependency on module-level or
  external state.
- **no-throw**: the three functions MUST NOT throw for any input within its declared
  parameter type (`string | null | undefined` for `hash`/`message`, `number` for `max`);
  every branch each function can take returns a value.

