
- **Decision**: `0.0.0.0` and both the bracketed (`"[::1]"`) and
  unbracketed (`"::1"`) forms of the IPv6 loopback address are included in
  `loopbackHosts` alongside `"localhost"` and `"127.0.0.1"`.
  **Rationale**: Not stated in a source comment. `0.0.0.0` is commonly used
  as a local server's bind-all address rather than strictly "loopback," and
  `URL.host` can surface an IPv6 literal with or without its brackets
  depending on how the `baseURL` string was written, so both spellings are
  listed to avoid a false negative on either form.
  **Approved**: pending
- **Decision**: `nativeTagsURL(baseURL:)` strips trailing slashes both
  before and after removing the `/v1` suffix, rather than once.
  **Rationale**: Not stated in a source comment. Stripping only once before
  the suffix check would miss a `baseURL` like
  `"http://localhost:11434/v1/"` (trailing slash after `/v1`), since
  `hasSuffix("/v1")` would see `"/v1/"` and not match; the two-pass sequence
  makes the function tolerant of a trailing slash on either side of the
  `/v1` segment.
  **Approved**: pending
- **Decision**: `parseSizes(_:)` decodes each `models` element individually
  via `try?` inside a private `Element` wrapper, rather than decoding
  `[Model]` directly and letting one bad element fail the whole array.
  **Rationale**: Stated directly in the source's doc comment: "one
  malformed entry ... is skipped rather than discarding the whole listing,
  which would fail the guard open server-wide." A single malformed entry
  MUST NOT blank every model's size, because `LocalInferenceGuard`'s
  downstream memory check depends on this data being present when it can be.
  **Approved**: pending
- **Decision**: A `parseSizes(_:)` entry is indexed under both its `name`
  and its `model` field (when present), rather than under one canonical
  key.
  **Rationale**: Stated directly in the source's doc comment: "Both `name`
  and the newer `model` key index the same entry so lookups succeed
  whichever form a config stored." Different call sites and Ollama API
  versions refer to a model by either field, and `size(of:in:)` must
  resolve either spelling without the caller knowing which one a given
  config uses.
  **Approved**: pending

