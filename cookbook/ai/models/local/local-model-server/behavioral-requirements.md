
- **namespace-shape**: The model server helper MUST be a stateless namespace
  with no case and only shared members, so it functions as an
  uninstantiable namespace rather than a value or reference type with
  instance state.
- **concurrency-safety**: Every one of the model server helper's four
  functions MUST be callable concurrently, from any execution context,
  without external synchronization. The helper carries no case, no stored
  instance property, and no instance is ever constructed or passed
  anywhere — the only stored value, the loopback host set, is immutable and
  computed once, so there is no mutable state for a concurrent call to race
  against.
- **synchronous-non-throwing**: None of loopback detection, native tags URL
  derivation, the response parser, or the size resolver MUST be
  asynchronous or fallible in a way that suspends or interrupts the caller;
  each MUST execute synchronously and return its result (a yes/no, an
  optional URL, a map of sizes, or an optional integer size) directly,
  including when its input is malformed.
- **no-side-effects**: The model server helper's four functions MUST perform
  no file-system access, network request, process launch, or notification;
  each MUST compute its result purely from its arguments (and, for native
  tags URL derivation and the response parser, from standard URL and data
  parsing applied to that input).
- **loopback-hosts-literal-set**: The loopback host set MUST contain exactly
  these five string literals, and no others: `"localhost"`, `"127.0.0.1"`,
  `"0.0.0.0"`, `"::1"`, `"[::1]"`.
- **is-loopback-host-extraction**: Loopback detection MUST parse the base
  URL and read its host component as the candidate to test.
- **is-loopback-case-insensitive-compare**: Loopback detection MUST
  lowercase the extracted host before comparing it against the loopback
  host set.
- **is-loopback-membership-result**: Loopback detection MUST return true if
  and only if the lowercased host is a member of the loopback host set, and
  false otherwise.
- **is-loopback-unparseable-false**: Loopback detection MUST return false
  when the base URL cannot be parsed, or the parsed URL has no host
  component (covers an empty base URL and a scheme-less string such as
  `"localhost:11434"`, whose host cannot be determined).
- **native-tags-url-whitespace-trim**: Native tags URL derivation MUST trim
  leading and trailing whitespace from the base URL before any other
  processing.
- **native-tags-url-strip-trailing-slashes-first-pass**: Native tags URL
  derivation MUST repeatedly strip a trailing `"/"` character from the
  trimmed string until none remains, before checking for a `"/v1"` suffix.
- **native-tags-url-strip-v1-suffix**: Native tags URL derivation MUST strip
  one trailing three-character `"/v1"` suffix, compared case-insensitively,
  from the string produced by the first slash-stripping pass.
- **native-tags-url-strip-trailing-slashes-second-pass**: Native tags URL
  derivation MUST repeatedly strip a trailing `"/"` character again after
  the `"/v1"` suffix has been removed, until none remains.
- **native-tags-url-empty-yields-nil**: Native tags URL derivation MUST
  return nothing when the fully-trimmed string is empty.
- **native-tags-url-append-and-construct**: Native tags URL derivation MUST
  append the literal path `"/api/tags"` to the fully-trimmed, non-empty
  string and construct the resulting URL; it MUST return nothing if that
  construction fails.
- **parse-sizes-decode-shape**: The response parser MUST decode the
  response body as data matching the shape `{"models": [{"name": string or
  absent, "model": string or absent, "size": integer or absent}, ...]}`.
- **parse-sizes-whole-decode-failure-empty**: The response parser MUST
  return an empty map when the top-level response does not match that shape
  at all (malformed data, or a missing/wrong-typed `models` key).
- **parse-sizes-per-element-tolerance**: The response parser MUST decode
  each element of the `models` array individually, so that one element
  failing to decode MUST be dropped without causing any other element in the
  array to be dropped.
- **parse-sizes-missing-size-excluded**: The response parser MUST exclude a
  decoded entry from the returned map under any key when that entry's
  `size` field is absent.
- **parse-sizes-dual-key-indexing**: The response parser MUST store a
  decoded entry's `size` under its `name` key when `name` is present, and
  MUST independently store the same `size` value under its `model` key when
  `model` is present; an entry with both fields present MUST be indexed
  under both keys.
- **parse-sizes-neither-key-excluded**: The response parser MUST exclude a
  decoded entry from the returned map entirely when it has neither a `name`
  nor a `model` value, regardless of whether `size` is present.
- **parse-sizes-array-order-last-write-wins**: When two entries in `models`
  produce the same map key (through either their `name` or `model` field),
  the response parser MUST resolve the collision to the value of whichever
  entry is later in the `models` array — ordinary last-write-wins map
  assignment — with no de-duplication or validation against the collision.
- **size-of-exact-match**: The size resolver MUST return the stored size
  when the sizes map contains that exact model key.
- **size-of-latest-fallback**: The size resolver MUST return the size stored
  under the model name suffixed with `":latest"` when the exact model key is
  absent from the sizes map and the `":latest"`-suffixed key is present.
- **size-of-total-miss-nil**: The size resolver MUST return nothing when
  neither the exact model key nor the `":latest"`-suffixed key is present in
  the sizes map.

