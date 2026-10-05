
- **Empty input**: an empty value MUST be refused.
- **Boundary values at the control-character edges**: `U+001F` MUST be
  refused, `U+0020` MUST be accepted, `U+007E` MUST be accepted, `U+007F`
  MUST be refused, and `U+0080` MUST be accepted.
- **Boundary: a value that is only a dot**: `"."` and `".."` MUST be refused
  identically to a longer leading-dot name such as `".ssh"`.
- **Malformed input**: not applicable as a distinct condition — the input is
  always a well-formed sequence of Unicode scalars for any argument a caller
  can construct, so the safety check has no notion of "malformed" input; it
  never fails regardless of content, including combining sequences and
  emoji.
- **Concurrent access**: not applicable in the shared-mutable-state sense —
  the safety check is a pure function of its argument and holds no state of
  any kind. Concurrent calls from multiple threads or concurrency contexts
  MUST produce results that depend only on each call's own value, never on
  the order or overlap of other calls.
- **Error states (dependency unavailable)**: not applicable — the safety
  check performs no file, network, or database access; it reads only the
  scalars of the value, so there is no dependency that can be unavailable.
- **Offline / disconnected state**: not applicable — the safety check does
  not operate over a network; it is a synchronous, local string
  computation.
- **Already-encoded separators are not decoded**: a value already
  containing an encoded separator, such as `"a%2Fb"` or `"a%2E%2E"`, MUST be
  accepted; the caller that splices the accepted value in verbatim is
  responsible for never decoding it afterward, since decoding after this
  check would reintroduce a separator behind the check.
- **Unbounded length**: the safety check MUST accept or refuse a value of
  any length according only to the shape rules above; no minimum length is
  enforced beyond non-emptiness and no maximum length is enforced at all.

