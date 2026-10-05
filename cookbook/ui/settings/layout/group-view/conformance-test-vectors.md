
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| group-view-001 | card-surface | Construct the component with title "Example" | The card is filled with the `.elevatedSurface` role, has no stroke, and has a 10pt corner radius |
| group-view-002 | card-view-access | Construct the component, then read its card property from outside the type | Returns the same card instance the component displays |
| group-view-003 | header-from-title | Construct the component from title "Example" | The constructed header's displayed title is "Example" |
| group-view-004 | arbitrary-header-view | Construct the component with a custom view as its header | That custom view is the arranged element above the card |
| group-view-005 | header-above-card | Construct the component | The outer stack's arranged order is [header, card] |
| group-view-006 | header-card-spacing | Construct the component | The spacing between the header and the card is 6.0 |
| group-view-007 | outer-stack-edge-pinning | Construct the component | The header-and-card stack fills the component's own bounds edge-to-edge, with zero inset on all four edges |
| group-view-008 | header-width-match | Construct the component | The header's width matches the header-and-card stack's width |
| group-view-009 | card-width-match | Construct the component | The card's width matches the header-and-card stack's width |
| group-view-010 | row-area-edge-pinning | Construct the component | The internal row area fills the card's bounds edge-to-edge, with zero inset on all four edges |
| group-view-011 | row-stacking | Construct the component | The internal row area is vertical, leading-aligned, with `0` spacing between rows |
| group-view-013 | superview-width-match | Add the constructed component as a child of a parent container | The component's width matches the parent's width |
| group-view-014 | width-match-skip-without-superview | Construct the component and let it settle with no parent | No width match is attempted; no crash occurs from a missing parent |
| group-view-015 | row-append | Add a row to the group | The added view is wrapped in a row that becomes the last row in the card; the number of rows in the card grows by one |
| group-view-016 | default-row-style | Add a row with no style specified | The added row's style is the standard row style |
| group-view-017 | added-row-width-match | Add a row to the group | The new row's width matches the row area's width |
| group-view-018 | self-hiding-content-wiring | Add a row whose content can report when it hides itself, then have that content report hiding | The wrapping row's hidden state re-syncs to the content's hidden state and separators are recomputed (observable via a subsequent row's separator state changing) |
| group-view-019 | separator-recompute-on-add | Add row A, then add row B | Recomputation after each addition is observable — whether row B's row shows a separator reflects row A's row's hidden state at the time row B was added |
| group-view-020 | separator-visibility | Add three standard-style, not-hidden rows in sequence | The second and third rows show a separator; only the first does not |
| group-view-021 | first-row-headless | Add a single row as the only row | That row's divider is hidden |
| group-view-023 | confines-to-ui-thread | Attempt to construct or mutate the component from off the UI thread | The call is rejected by the platform's UI-thread confinement enforcement (compile-time on platforms with static isolation checking, runtime-checked otherwise) |
| group-view-024 | row-visibility-binding | Hide a row's wrapped content, then have the row resynchronize its visibility | The row's own hidden state becomes `true` |
| group-view-025 | row-visibility-at-construction | Construct a row whose wrapped content's hidden state is `true` | Immediately after construction returns, the row's own hidden state is `true` |
| group-view-026 | separator-collapse | Turn a row's separator visibility off (from on) | The row's divider becomes hidden; the space reserved for it becomes `0` |
| group-view-027 | separator-expansion | Turn a row's separator visibility on (from off) | The row's divider becomes visible; the space reserved for it becomes `1.0`pt |
| group-view-028 | separator-write-idempotency | Set a row's separator visibility to its own current value | Neither the divider's hidden state nor the reserved space's height changes as a result of this assignment |
| group-view-029 | separator-inset | Inspect a standard-style row's layout | The divider is inset 14pt from the row's leading edge; the divider reaches the row's trailing edge with no additional inset |
| group-view-030 | row-content-padding | Inspect a standard-style row's layout | The content's top edge is inset 9pt below the divider band; the content's bottom edge is inset 9pt from the row's bottom edge |
| group-view-031 | continuation-padding | Inspect a continuation-style row's layout | The content's top edge has no inset from the divider band (`0`); the content's bottom edge is still inset 9pt from the row's bottom edge |
| group-view-032 | row-content-horizontal-inset | Inspect any row's layout | The content's leading edge is inset 14pt from the row's leading edge; the content's trailing edge is inset 14pt from the row's trailing edge |

Two implementation-only construction-rule checks (autoresizing-mask
disabling and the rejection of a coder-based/decoding constructor on the
component and on a row) are platform mechanics rather than portable
behavior; see Platform Notes for how the source verifies
them there.

