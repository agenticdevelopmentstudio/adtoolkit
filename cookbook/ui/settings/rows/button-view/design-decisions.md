
**Decision**: Fill is the default value of the placement parameter.
**Rationale**: Per the source's own doc comment, the default is `.fill` "because that is what every caller before this parameter got, and a settings row that silently changed shape would be a worse surprise than a verbose call site."
**Approved**: pending

**Decision**: The leading and centered placements bound the button's trailing edge (and, for centered, its leading edge) with inequality constraints rather than pinning them exactly.
**Rationale**: Per the source's own comments: the trailing constraint is "less-than, not equal: the row is as wide as the card, and an equal trailing edge is the stretch `.fill` is for," and the `.centered` leading constraint is "greater-than... for the same reason as the trailing one; the centre anchor does the placing."
**Approved**: pending

**Decision**: (AppKit) `init(frame:)` and `init?(coder:)` are overridden only to call `fatalError`, rather than being omitted.
**Rationale**: `ButtonView` has no valid state without a `ButtonViewModel`. Blocking the two inherited `NSView` initializers this way means a caller who reaches them through generic `NSView`-typed construction code (e.g. Interface Builder decoding) crashes immediately with a diagnosable message, instead of silently producing a `ButtonView` with no view model.
**Approved**: pending

**Decision**: This recipe calls the component's container a "row" throughout, even though the source's own comments use both "row" (in the `Placement` doc comment: "where the button sits in the row it is given") and "card" (in the `.fill` and `.leading` case comments: "stretched across the whole card"; "the row is as wide as the card").
**Rationale**: The two words refer to the same concept in this file; "row" is kept as the single term for consistency with how a settings-row view's container is described elsewhere in the cookbook — `adtoolkit://cookbook/ui/settings/layout/header-view` and `adtoolkit://cookbook/ui/settings/layout/horizontal-stack-view` both describe the settings-row-view contract as "the marker protocol every settings-row view in this system adopts" — and the source's own inconsistency is recorded here rather than silently smoothed over.
**Approved**: pending

**Decision**: (AppKit) This recipe describes `Self.pinToEdges(button, of: self)` (used in **fills-view-in-fill-placement**) as pinning all four edges of the button to the corresponding edges of the component.
**Rationale**: `pinToEdges` is not defined in `ButtonView.swift`, but its implementation was read directly: `static func pinToEdges(_ view: NSView, of container: NSView)` in `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/ViewLayout.swift` activates exactly four equal constraints — `view`'s top, leading, trailing, and bottom anchors to `container`'s corresponding anchors — confirming the `.fill` case comment ("Stretched across the whole card") describes the same behavior this recipe asserts.
**Approved**: pending

