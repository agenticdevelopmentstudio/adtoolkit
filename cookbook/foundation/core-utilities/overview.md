
This recipe covers six independent foundation-tier utilities. Each has no
dependency on anything else in this recipe or on any other part of the
package; together they form the lowest tier of the toolkit — the tier every
other logic and UI component is built on top of.

- **An encoding-skip wrapper** — removes a field from a model's standard
  structured encoding and decoding entirely, so a value can exist on a model
  without ever appearing in its JSON representation.
- **Secret storage** — a static, namespace-style API over the system
  credential store's generic-password items, with built-in migration across
  a configurable access group and a list of retired service identifiers.
  Consumed directly by a secure-settings storage provider and by the AI
  plugin kit's secret-storing component.
- **A logger factory contract** — a contract that gives any conforming type
  a structured logger derived from the app's bundle identifier and the
  type's own name, with no boilerplate at each call site beyond a single
  factory-backed property declaration.
- **Float clamping** — a single clamp-to-range extension method; pure
  arithmetic, no state.
- **Semantic version parsing** — a `major.minor.patch` parser and comparable
  value type with an explicit upper bound on each component, guarding
  arithmetic callers (such as an extension manifest's engine-range caret
  ceiling) against integer overflow traps.
- **Text folding** — a single case-and-diacritic folding helper for
  locale-independent text matching, used by a command-palette model and an
  extension quick-pick model.

None of the six utilities depends on any UI framework; none renders
anything, holds view state, or performs networking.

