
**Decision**: Document only what `WindowController.swift` itself adds — the
typed `viewController` accessor and `WindowContentViewController` — and treat
all window lifecycle, frame-persistence, visibility-persistence, and HUD
behavior as inherited unchanged from `SingleWindowController`, cited through
`depends-on` rather than restated.
**Rationale**: `SingleWindowController` already has its own canonical recipe
(`adtoolkit://cookbook/ui/windows/single-window-controller`); restating its
requirements here would duplicate content that has its own source of truth
and risks drift when that recipe changes, and would misrepresent this file's
actual (much smaller) scope.
**Approved**: pending

**Decision**: Document `WindowContentViewController.init?(coder:)`'s
runtime-only `fatalError` as a quirk rather than describing it as matching
`SingleWindowController`'s coder-rejection pattern.
**Rationale**: source fidelity forbids smoothing over an inconsistency —
`SingleWindowController.init?(coder:)` is marked `@available(*, unavailable)`
(a compile-time failure), while `WindowContentViewController.init?(coder:)`
carries no such attribute and remains a normally callable initializer that
only fails at runtime when actually invoked.
**Approved**: pending

