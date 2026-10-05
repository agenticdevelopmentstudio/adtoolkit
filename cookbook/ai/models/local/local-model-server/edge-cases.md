
- **Empty base URL to loopback detection.** Loopback detection with an
  empty base URL MUST return false — parsing fails to yield a host
  (is-loopback-unparseable-false).
- **Scheme-less base URL to loopback detection.** A base URL with no
  `http://` or `https://` prefix (e.g. `"localhost:11434"`) parses with no
  host, so loopback detection MUST return false even though a human reader
  would recognize the string as local (is-loopback-unparseable-false).
- **Base URL that trims to empty for native tags URL derivation.** A base
  URL such as `"/v1"` or `"///"` reduces, through the slash- and
  `/v1`-stripping passes, to an empty string, and native tags URL derivation
  MUST return nothing — the same outcome as a literally empty base URL
  (native-tags-url-empty-yields-nil).
- **Repeated trailing slashes.** A base URL such as
  `"http://localhost:11434/v1////"` MUST resolve to
  `"http://localhost:11434/api/tags"`; both stripping passes loop until no
  trailing slash remains, so any number of trailing slashes is removed, not
  just one (native-tags-url-strip-trailing-slashes-first-pass,
  native-tags-url-strip-trailing-slashes-second-pass).
- **Mixed-case `/v1` suffix.** `"http://localhost:11434/V1"` MUST also strip
  to `"http://localhost:11434/api/tags"`, because the suffix check is
  case-insensitive (native-tags-url-strip-v1-suffix).
- **Malformed data to the response parser.** Non-JSON bytes (e.g. `"not
  json"`) MUST yield an empty map, not a thrown error or a crash
  (parse-sizes-whole-decode-failure-empty).
- **Well-formed data, wrong top-level shape.** A response that is valid but
  does not contain a `models` array at all (e.g. `{}` or `{"models": {}}`)
  MUST also yield an empty map, because the outer shape fails to match
  (parse-sizes-whole-decode-failure-empty).
- **Partially malformed entries.** An entry array where some elements have
  wrong-typed fields MUST retain the well-formed elements and drop only the
  malformed ones, per element, rather than discarding the whole listing
  (parse-sizes-per-element-tolerance).
- **Colliding `name`/`model` keys across distinct entries.** Two different
  entries in `models` that happen to share the same string in their
  `name`/`model` fields MUST resolve to the later entry's `size` in the
  returned map, with no error and no validation of the collision
  (parse-sizes-array-order-last-write-wins).
- **Empty model string to the size resolver.** Resolving an empty model
  string MUST return nothing unless the sizes map literally contains the
  empty string as a key (it never does from a real `/api/tags` response,
  since Ollama model names are non-empty) — ordinary miss behavior, with no
  special-casing here (size-of-total-miss-nil).
- **Concurrent access.** Not applicable as a race concern: the model server
  helper holds no mutable state — its only stored value, the loopback host
  set, is immutable — so any number of concurrent calls to any of its four
  functions from any concurrent context simultaneously MUST produce no data
  race, by construction, with no synchronization required.
- **Offline or disconnected state.** Not applicable to this component
  directly: it performs no network I/O itself. Native tags URL derivation
  only derives a URL string, and the response parser only parses data the
  caller has already fetched (or failed to fetch); connectivity loss and
  its handling are the caller's concern (the model catalog, a local
  provider model store, an inference guard), not this component's.
- **Missing or unreachable server / cancellation / timeout.** Not
  applicable to this component directly, for the same reason as offline
  state: there is no request, handle, or asynchronous task here to time
  out, go unreachable, or be cancelled. Every one of its functions is
  synchronous and non-throwing (synchronous-non-throwing).

