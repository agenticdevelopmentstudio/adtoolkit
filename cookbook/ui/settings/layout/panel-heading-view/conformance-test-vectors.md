
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-heading-view-001 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (compile-time on platforms with static isolation checking, runtime-checked otherwise) |
| panel-heading-view-002 | exposes-title-label | Construct the component with title "Section" | Its title label is accessible from outside the component |
| panel-heading-view-003 | exposes-caption-label | Construct the component with title "Section" and caption "Some blurb" | Its caption-label accessor is present and equals the constructed caption view's own label |
| panel-heading-view-004 | exposes-caption-label | Construct the component with title "Section" (no caption argument) | Its caption-label accessor is absent |
| panel-heading-view-005 | styles-title-as-primary-heading | Construct the component with title "Section" | The title label's color role is primary-text and its text role is heading |
| panel-heading-view-006 | sets-title-text-from-caller | Construct the component with title "General" | The title label's displayed text is "General" |
| panel-heading-view-007 | creates-caption-view-when-caption-given | Construct the component with title "Section" and caption "Some blurb" | The stack's arranged children include a caption view whose label reads "Some blurb" |
| panel-heading-view-008 | omits-caption-view-when-caption-nil | Construct the component with title "Section" and caption defaulted/absent | The stack's arranged children contain no caption view; the caption-label accessor is absent |
| panel-heading-view-009 | stacks-title-and-caption-vertically-leading-aligned | Construct the component with title "Section" and caption "Some blurb" | The internal stack's orientation is vertical, its alignment is leading, and its arranged children are the title label followed by the caption view, in that order |
| panel-heading-view-010 | spaces-title-from-caption | Construct the component (with or without a caption) | The internal stack's spacing equals the standard caption-spacing value (currently 6.0) |
| panel-heading-view-011 | matches-caption-width-to-stack | Construct the component with title "Section" and caption "Some blurb" | An active constraint equates the caption view's width to the stack's width; no equivalent constraint exists for the title label |
| panel-heading-view-012 | fills-bounds-with-zero-inset | Construct the component | Active constraints pin the stack's top/leading/trailing/bottom edges to the view's corresponding edges, each with zero constant |
| panel-heading-view-013 | requires-title-at-construction | Attempt to construct the component via a bare/default construction path that supplies no title | Construction fails rather than producing a usable instance (see Platform Notes for the source's exact mechanism and message) |
| panel-heading-view-014 | requires-title-at-construction | Attempt to construct the component via a deserializing/decoding-based construction path | Construction fails rather than producing a usable instance (see Platform Notes for the source's exact mechanism and message) |

Vectors 001, 013, and 014 are compile-time or trap checks, not conventional
runtime unit tests: 001 verifies rejection under the platform's UI-thread
isolation checking, and 013/014 verify an unconditional trap; run each as
the static or trap check it is.

