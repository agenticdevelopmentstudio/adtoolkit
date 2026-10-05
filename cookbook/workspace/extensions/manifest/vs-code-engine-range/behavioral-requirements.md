
- **rawvalue-preservation**: `VSCodeEngineRange.rawValue` MUST hold the
  string exactly as passed to `init?(_:)`, including any leading or
  trailing whitespace, even though recognition of the string's shape
  operates on a separately trimmed copy.
- **whitespace-trimming**: `init?(_:)` MUST trim leading and trailing
  whitespace (Foundation's `.whitespaces` character set) from the input
  before attempting to recognize its shape.
- **inner-whitespace-rejection**: `init?(_:)` MUST NOT accept whitespace
  anywhere inside the trimmed string; a string such as `">= 1.74.0"` or
  `"^ 1.74.0"` MUST fail to parse.
- **wildcard-recognition**: an input that trims to exactly `"*"` MUST parse
  to a requirement whose three bases are all `0`, whose three must-equal
  flags are all `false`, and whose `isMinimum` is `false`.
- **caret-operator**: a trimmed input beginning with `"^"` MUST always
  clear the patch component's must-equal flag, and MUST also clear the
  minor component's must-equal flag unless the parsed major base is `0`.
- **minimum-operator**: a trimmed input beginning with `">="` (and not with
  `"^"`) MUST set `isMinimum` to `true` and leave all three must-equal
  flags exactly as parsed from the three components.
- **exact-operator**: a trimmed input beginning with neither `"^"` nor
  `">="` MUST leave every component's must-equal flag exactly as parsed
  from that component (a numeric component's flag `true`, an `"x"`
  component's flag `false`) and MUST leave `isMinimum` `false`.
- **x-wildcard-component**: a component written as the single character
  `"x"` MUST parse to a base of `0` with that component's own must-equal
  flag `false`, independent of the other two components' values.
- **numeric-component**: a component consisting only of ASCII digit
  characters MUST parse to that integer value with the component's
  must-equal flag `true`, before any operator-driven clearing is applied.
- **component-count**: after the operator prefix is removed and any
  pre-release suffix is dropped, the remaining body MUST split into exactly
  three `.`-separated components (using
  `split(separator:omittingEmptySubsequences:false)`, so an empty component
  from a doubled or trailing `.` counts as a component); a body that does
  not split into exactly three components MUST cause `init?(_:)` to return
  `nil`.
- **prerelease-suffix-tolerance**: when the body contains a `-` character,
  `init?(_:)` MUST discard that character and everything after it before
  splitting into components, and the presence of such a suffix (for
  example `"-insider"` or `"-20240101"`) MUST NOT by itself cause
  `init?(_:)` to return `nil`; the discarded suffix text plays no further
  role in `accepts(_:)`, `minimumVersion`, or `isUnconstrained`.
- **component-bound**: the three parsed integer components MUST be
  validated by constructing `SemanticVersion("<major>.<minor>.<patch>")`
  from them; a component that is empty, contains a non-ASCII-digit
  character, or exceeds `SemanticVersion`'s own plausibility bound
  (`Int32.max`) MUST cause `init?(_:)` to return `nil` rather than
  overflowing or trapping.
- **unsupported-grammar-rejection**: a trimmed input that is not the bare
  `"*"` and does not fit `(^|>=)?` followed by exactly three
  numeric-or-`x` `.`-separated components (with an optional `-` suffix)
  MUST cause `init?(_:)` to return `nil`; this includes any npm-style
  shape VS Code's own grammar never implements — a `"~"`, `">"`, `"<"`, or
  `"||"` operator, a hyphen version range, a two-component version such as
  `"1.74"`, a bare single component such as `"1"`, the literal string
  `"latest"`, a lone `"^"` with no version, and the empty string.
- **accepts-minimum-comparison**: when `isMinimum` is `true`,
  `accepts(_:)` MUST return `true` if and only if the tested version's
  `(major, minor, patch)` tuple is greater than or equal to the
  requirement's `(majorBase, minorBase, patchBase)` tuple under
  lexicographic (major, then minor, then patch) ordering.
- **accepts-sub-one-compatibility-rewrite**: when `isMinimum` is `false`,
  the tested version's `major` equals `1`, the requirement's `majorBase`
  equals `0`, and at least one of the requirement's three must-equal flags
  is `false`, `accepts(_:)` MUST evaluate the tested version against a
  rewritten requirement of `majorBase: 1` (must-equal `true`), `minorBase:
  0` (must-equal `false`), `patchBase: 0` (must-equal `false`) instead of
  the requirement as parsed — i.e. any sub-1.0.0 requirement that leaves
  slack anywhere MUST be satisfied by every version whose major is `1`.
- **accepts-sub-one-exact-refusal**: when the requirement's `majorBase`
  equals `0` and all three of its must-equal flags are `true` (a fully
  pinned sub-1.0.0 version such as `"0.10.0"`), the rewrite in
  `accepts-sub-one-compatibility-rewrite` MUST NOT apply, and `accepts(_:)`
  MUST reject every tested version whose `major` is not exactly `0`.
- **accepts-major-comparison**: after any rewrite, `accepts(_:)` MUST
  return `false` when the tested version's `major` is less than the
  (possibly rewritten) `majorBase`, MUST return the negation of the
  (possibly rewritten) major must-equal flag when the tested version's
  `major` is greater than `majorBase`, and MUST proceed to compare minor
  components only when the two majors are equal.
- **accepts-minor-comparison**: once majors are equal, `accepts(_:)` MUST
  return `false` when the tested version's `minor` is less than
  `minorBase`, MUST return the negation of the minor must-equal flag when
  the tested version's `minor` is greater than `minorBase`, and MUST
  proceed to compare patch components only when the two minors are equal.
- **accepts-patch-comparison**: once minors are equal, `accepts(_:)` MUST
  return `false` when the tested version's `patch` is less than
  `patchBase`, MUST return the negation of the patch must-equal flag when
  the tested version's `patch` is greater than `patchBase`, and MUST
  return `true` when major, minor, and patch are all equal to their
  respective bases.
- **minimum-version-floor**: `minimumVersion` MUST equal
  `SemanticVersion(major: majorBase, minor: minorBase, patch: patchBase)`
  taken directly from the parsed requirement; it MUST NOT reflect the
  sub-1.0.0 rewrite that `accepts(_:)` applies at comparison time, so for a
  requirement such as `"^0.10.5"` it reports `0.10.5`, not `1.0.0`.
- **is-unconstrained-predicate**: `isUnconstrained` MUST be `true` if and
  only if `isMinimum` is `false` and all three bases are `0` and all three
  must-equal flags are `false`; this is `true` for `"*"` and for an all-`x`
  range such as `"x.x.x"`, and `false` for every other range, including a
  literal `"0.0.0"` and a `">=0.0.0"` minimum.
- **value-semantics**: `VSCodeEngineRange` MUST be an immutable value safe to
  share across threads and concurrency domains, comparable for equality and hashable, and
  convertible to text, with its `description`
  returning `rawValue` exactly.
- **concurrency-safety**: `VSCodeEngineRange` instances MUST be safe to
  construct and to query (`accepts(_:)`, `minimumVersion`,
  `isUnconstrained`, `description`) concurrently, from any thread or
  concurrency domain, without external synchronization, because every stored property
  on `VSCodeEngineRange` and on the private `Requirement` it wraps is a
  `let` and neither type declares any mutable shared state.

