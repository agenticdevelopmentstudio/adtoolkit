
- **SwiftUI**: The date, error-normalization, blank-string, JSON-value,
  rail-path, and slug pieces need no change — none depends on AppKit/UIKit.
  Only the form/notice factory's form-hosting-view construction is
  AppKit/UIKit-specific; a SwiftUI host would replace it with a SwiftUI
  view driven by the same form state (per the related HTDV Engine recipe's
  SwiftUI note), keeping the notice factory's one-field-spec logic
  unchanged.
- **Compose**: Model the JSON document value type as a Kotlin `sealed
  class` with the same seven cases and a hand-written `equals`/`hashCode`
  implementing the same integral-number cross-equality this file's own
  comment explains (Kotlin data-class equality would otherwise compare
  sealed subclasses first, the same bug this source works around). Model
  the date helper with `kotlinx-datetime`'s `Instant` and a fixed-format
  ISO string builder for the wire-formatting operation. Reimplement the
  slug-projection operation as the same lowercase-and-collapse character
  scan, and the error normalizer as a function normalizing any `Throwable`
  into a sealed error type.
- **React/Web**: Model the JSON document value type as a TypeScript
  `JsonValue` union with a hand-written `deepEqual` that treats an integral
  `number` as equal to the same-valued `number` it decodes back as
  (JavaScript has only one numeric type, so the integer/number split this
  source encodes may not need reproducing — note the platform difference
  rather than force it). Use `Date.prototype.toISOString()` in place of the
  wire-formatting operation and `Intl.DateTimeFormat` in place of the
  human-readable formatter. Reimplement the slug-projection operation and
  pattern as the same character scan and regular expression, and the error
  normalizer as a function normalizing any thrown value into a tagged
  error union.
- **AppKit / UIKit**: This is the source platform.
  `packages/apple/AgenticToolkit/Hub/Features/Support/HubDates.swift`,
  `HubError+Wrap.swift`, `HubText.swift`, `JSONValue.swift`,
  `RailPath.swift`, and `Slug.swift` import only `Foundation` (plus
  `AgenticToolkitHTDV` for the date helper's/rail-path's HTDV types) and
  hold no AppKit/UIKit import of their own; only `FormDetails.swift` reaches
  into a platform-specific view controller, and it does so through
  `FormViewController`, which exists in both an AppKit variant
  (`packages/apple/AgenticToolkit/HTDV/Views/macOS/FormViewController.swift`)
  and a UIKit variant
  (`packages/apple/AgenticToolkit/HTDV/Views/iOS/FormViewController+UIKit.swift`) —
  the other six files are shared unchanged between macOS and iOS. The
  closure-taking form of `HubError.wrap` (`HubError.wrap(isolation:_:)`)
  declares its `isolation` parameter as `isolated (any Actor)? =
  #isolation`, so a caller's `body` closure runs under the caller's own
  actor isolation — main actor, a specific actor, or nonisolated — instead
  of being forced `nonisolated`, per the source's own comment that this
  lets a `@MainActor` caller "capture `self`" and still compile under Swift
  6 strict concurrency "without hoisting reads out or wrapping writes in
  `MainActor.run`." This is a compile-time-only guarantee — no runtime
  assertion is possible for it — which is why `SupportTests.swift` carries
  three test methods that exist solely to fail to build if this isolation
  parameter regresses, and why the corresponding Conformance Test Vector
  was removed from the normative table above rather than translated into a
  neutral input/expected pair.
- **WinUI 3**: Model the JSON document value type as a C# type with the
  same seven-case shape and an `IEquatable<JSONValue>` implementation giving
  the same `int`/`double` cross-equality, serialized with
  `System.Text.Json`. Model the date helper with `DateTimeOffset` and the
  fixed format string `"yyyy-MM-dd'T'HH:mm:ss.fff'Z'"` for the equivalent
  of the wire-formatting operation, parsing with `DateTimeOffset.TryParse`
  under `DateTimeStyles.RoundtripKind` in place of the fractional/whole
  two-step parse. Reimplement the slug pattern with
  `System.Text.RegularExpressions.Regex`, and model the error normalizer as
  a static method that normalizes any `Exception` into a domain-error-
  derived exception type, with the closure overload taking a
  `Func<Task<T>>` in place of the caller-isolation-preserving Swift
  overload (WinUI 3 has no actor-isolation analog to preserve).

