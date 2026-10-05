
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-scroll-view-001 | document-view-flipped | Inspect the document view's coordinate system on a newly constructed component | It reports a top-down coordinate system |
| panel-scroll-view-002 | content-top-leading-anchored | Inspect the document view's active constraints against the scroll view's viewport on a newly constructed component | The document view's top and leading edges are each constrained equal, constant 0, to the viewport's top and leading edges |
| panel-scroll-view-003 | content-width-matches-viewport | Install content whose intrinsic content width is wider than the current viewport, then resize the scroll view's frame | The content's width always equals the viewport's width; it never exceeds or falls short of the viewport width regardless of the content's intrinsic width |
| panel-scroll-view-004 | content-min-height-viewport | Install content whose intrinsic content height is smaller than the viewport height | The content's height is at least the viewport's height, filling the viewport with no gap below |
| panel-scroll-view-005 | content-fills-document-edges | Install content, then inspect the edge constraints between it and the document view | The content's top, leading, trailing, and bottom edges are each constrained equal, constant 0, to the document view's corresponding edges |
| panel-scroll-view-006 | content-replacement-removes-previous | Install content A, then install content B | After the second call, content A is no longer a child of the document view; only content B remains |
| panel-scroll-view-007 | content-replacement-resets-scroll-position | Scroll to the bottom of content A, then install content B | The scroll position returns to the top (origin) once content B is installed, as a side effect of removing content A's constraints rather than an explicit scroll reset |
| panel-scroll-view-008 | vertical-scroller-enabled | Inspect a newly constructed component | Its vertical scroll indicator is enabled |
| panel-scroll-view-009 | horizontal-scroller-enabled | Inspect a newly constructed component | Its horizontal scroll indicator is enabled |
| panel-scroll-view-010 | scrollers-autohide | Inspect a newly constructed component | Its scroll indicators autohide |
| panel-scroll-view-011 | background-transparent | Inspect a newly constructed component | It draws no background of its own |
| panel-scroll-view-013 | confines-to-ui-thread | Attempt to construct or call the set-content operation on the component from off the UI thread | Rejected by the platform's UI-thread confinement enforcement (compile-time on platforms with static isolation checking, runtime-checked otherwise) |
| panel-scroll-view-014 | programmatic-instantiation-only | Attempt to construct the component via a deserializing/decoding-based construction path | Rejected (compile-time when the construction path is marked unavailable; otherwise a trap); no instance is produced |
| panel-scroll-view-015 | content-width-matches-viewport | Host the component as one pane of a split view, record the split view's divider position, then install content whose intrinsic width is wider than the pane | The divider's position is unchanged after installation; the content's width still equals the viewport's width, never exceeding the pane's allotted width |

Test vector for the disabled-legacy-frame-system requirement
(**autoresizing-mask-disabled** in the source's own construction) moved to
Platform Notes, since it is a framework
construction rule with no equivalent on platforms that never had an
autoresizing-mask/frame-based layout system to disable in the first place.

