
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tab-pane-001 | header-text | The data source returns agent `"Claude"`, model `"Fable 5.1"`; reload | The agent label reads `"Claude · Fable 5.1"` |
| tab-pane-002 | header-text | The data source returns agent `"Claude"`, model `nil`; reload | The agent label reads `"Claude"` |
| tab-pane-003 | directory-text | The working directory is under the current user's home, e.g. `~/Projects/worktrees/tabs`; reload | The directory label reads `"~/Projects/worktrees/tabs"` |
| tab-pane-004 | branch-visibility | The data source's branch is non-nil, then a later reload with the same data source returning nil | The branch label is shown after the first reload and hidden after the second |
| tab-pane-005 | summary-hidden-by-default | Pane constructed and never reloaded | The summary label is hidden before any reload |
| tab-pane-006 | status-symbol-replacement | Replace the status glyphs with one symbol, then replace them again with one symbol | Only one status glyph remains after the second call, not two |
| tab-pane-007 | card-width-is-bounded | Content short enough that the measured width falls below `240` pt | The preferred content size's width reads `240` |
| tab-pane-008 | card-width-is-bounded | Content long enough that the measured width exceeds `340` pt | The preferred content size's width reads `340` |
| tab-pane-009 | card-height-has-a-floor-and-grows-with-content | Content taller than the height floor on the top edge | The preferred content size's height is greater than `136` and matches the pane's own measured height within `0.5` pt |
| tab-pane-010 | card-width-is-bounded; card-height-has-a-floor-and-grows-with-content | Content short enough to floor width and height on every edge (the slack that differs by edge is masked once content is at the floor) | All four edges report the same floored preferred content size |
| tab-pane-011 | selection-and-depth-are-reconciled | Pane never highlighted; stack depth never explicitly set | The agent label's role is the behind role before any highlight |
| tab-pane-012 | selection-and-depth-are-reconciled | Set highlighted to true | The agent label's role becomes the front (accent) role |
| tab-pane-013 | front-and-behind-cards-use-distinct-backgrounds | Card not highlighted vs. highlighted | The reported fill/border colors equal the window-background/border roles when behind, and the workspace-backdrop/outline roles when front |
| tab-pane-014 | front-card-overhangs-the-workspace-edge; behind-card-recedes-from-the-workspace-edge | Card highlighted vs. not, on every edge | The reported workspace overhang equals the workspace overlap (`1`) when front, and `-4` when behind at depth `1` on every edge |
| tab-pane-015 | behind-card-recedes-from-the-workspace-edge | Highlighted card vs. a card at depth `1` | The behind card's painted frame is inset `4` pt on every side and is smaller than the front card's frame on both axes |
| tab-pane-016 | vertical-edge-recession-accumulates-with-depth | Depths 1, 2, 3 on left/right edges | Recession is `4`, `8`, `12` pt respectively |
| tab-pane-017 | horizontal-edge-recession-is-constant | Depths 1, 2, 3 on top/bottom edges | Recession is `4` pt at every one of those depths |
| tab-pane-018 | paint-and-text-move-together | Card moved to a receded depth | The card's text frame moves in by the same inset as its painted frame |
| tab-pane-019 | front-card-overhangs-the-workspace-edge | Card at depth 0 | The card's text frame stays inside its bounds while its painted frame extends past those bounds on the workspace side |
| tab-pane-020 | depth-change-is-immediate-when-detached | Card not attached to a window; set depth to `2` | The card is not animating and its reported workspace overhang reflects the new depth immediately, with no animation |
| tab-pane-021 | depth-change-animates-when-attached-to-a-window | Card attached to a window; change depth | The card is animating and its set of in-progress move animations is non-empty during the transition |
| tab-pane-022 | selection-and-depth-are-reconciled | Highlighted state toggled true → false → true with varying stack-depth values, including `0` | The reported workspace overhang never reads as "front" while not highlighted, whatever depth was last reported |
| tab-pane-023 | front-and-behind-cards-differ-in-role-and-color | Card constructed (behind, depth ≥ 1) vs. highlighted (front) | The agent label's role is the behind role when behind and the front role when highlighted; the session/directory/branch labels never fall below the dimmer-but-readable behind roles from the front/behind role table at any depth |
| tab-pane-024 | close-button-callback | Close callback set; close button clicked | The callback fires exactly once |
| tab-pane-025 | context-menu-is-delegated | Delegate set, returns a specific menu for a given event | Requesting a context menu returns that exact menu, and the delegate is asked exactly once |
| tab-pane-026 | close-button-sits-on-the-outward-end | Pane constructed on each of the four edges | On the left edge, the close button is the header's first element; on top/right/bottom, it is the last |
| tab-pane-027 | subviews-carry-tab-scoped-accessibility-identifiers | Pane constructed with a known tab ID | The root view and each labeled subview expose `tab-pane.<part>.<tabID>` |
| tab-pane-028 | session-text | The data source returns session name `"tabs"`; reload | The session label reads `"tabs"` |
| tab-pane-029 | title-and-preferred-content-size | The data source returns session name `"tabs"`; reload | The title reads `"tabs"` (matching the session label) and the preferred content size equals the card's content size |
| tab-pane-030 | nil-data-source | No data source is set; reload | The view is loaded but no label, title, or preferred content size is touched |
| tab-pane-031 | redundant-depth-set-is-a-no-op | Card attached to a window; set stack depth to its own current value | The set of in-progress move animations stays empty and the reported workspace overhang is unchanged, because a redundant set never re-runs the depth-change logic |
| tab-pane-032 | recession-does-not-increase-past-depth-three | Vertical edge; depth set past the maximum stack depth (`4` beyond it) | The reported workspace overhang equals the value at the maximum depth, not any larger |
| tab-pane-033 | labels-do-not-intercept-clicks | Card constructed on any edge | None of the agent, session, directory, branch, or summary labels are selectable |
| tab-pane-034 | status-glyph-has-an-accessible-label | Replace the status glyphs with one symbol whose accessibility label is `"Busy"` | The resulting glyph's accessibility label reads `"Busy"`, independent of its symbol name |
| tab-pane-035 | component-does-not-poll-its-data-source | The data source's answers change after construction, with no reload call | No label, title, or preferred content size changes on its own; content changes only appear after an explicit reload |
| tab-pane-036 | directory-text | The data source returns a working directory outside the current user's home, e.g. `/tmp/repo/.claude/worktrees/tabs`; reload | The directory label reads that path unabbreviated |
| tab-pane-037 | context-menu-is-delegated | Delegate is nil (or set but returns nil for the event); a menu-triggering event fires | Requesting a context menu falls back to the platform's standard context menu |
| tab-pane-038 | header-text; session-text; branch-visibility; summary-visibility; title-and-preferred-content-size | Reload once with short content (agent `"C"`, no model, session `"s"`, branch `"b"`, no summary), then again after every field changes and grows past the maximum width | The agent, session, and branch labels follow the new values; the summary label becomes shown once a summary appears; the preferred content size's width moves from the minimum to the maximum between the two calls |
| tab-pane-039 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

