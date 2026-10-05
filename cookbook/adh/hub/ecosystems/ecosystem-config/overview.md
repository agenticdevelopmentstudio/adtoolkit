
This component is five topic implementations that hang off one ecosystem's product
rail — a user-auth topic, a sign-in-apps topic, a feature-flags topic, a
server-bags topic, and a storage-tokens topic (a thin wrapper around a shared token
rail) — plus the data models and five data-source interfaces they share, and a
matching client-side data layer for the same five resources. Each topic resolves a
rail-relative navigation path into a level (a list of that ecosystem's
flags/bags/apps/tokens, with a create action) or a detail (a form specification for
viewing/editing one entity), orchestrating an injected data-source interface, domain
validation, and error normalization through a shared error type. A second,
independently maintained client layer implements the corresponding fetch operations
for the same five resources, consumed by presentation-layer panes and dialog-state
modules that are not part of this component's given sources. This is a **logic**
component: none of these five topics render anything themselves — they build
declarative form/level/detail value objects that a separate presentation layer
(outside these sources) turns into UI, and the second client layer is a set of plain
fetch-based operations with no view code of its own.

