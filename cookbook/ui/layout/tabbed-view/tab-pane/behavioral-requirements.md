
- **header-text**: On reload, the component MUST set the agent label to
  `"\(agent) · \(model)"` when the data source's model name is non-nil, and
  to the agent name alone when it is nil.
- **session-text**: On reload, the component MUST set the session label's
  text to the data source's session name.
- **directory-text**: On reload, the component MUST set the directory
  label's text to the data source's working directory with the current
  user's home directory prefix replaced by `~`, and MUST leave a path
  outside the home directory unabbreviated.
- **branch-visibility**: On reload, the component MUST set the branch
  label's text to the data source's branch when non-nil and MUST hide the
  branch label when the branch is nil.
- **summary-visibility**: On reload, the component MUST set the summary
  label's text to the data source's summary when non-nil and MUST hide the
  summary label when the summary is nil.
- **summary-hidden-by-default**: Before any reload runs, the summary label
  MUST start hidden.
- **status-symbol-replacement**: On reload (and on every replacement of the
  status glyphs), the component MUST remove any previously shown status
  glyphs before adding the new ones, so repeated calls MUST NOT accumulate
  elements.
- **title-and-preferred-content-size**: On reload, the component MUST set
  its title to the session label's text and MUST set its preferred content
  size to the card's current measured content size.
- **nil-data-source**: The reload operation MUST take no action beyond
  ensuring the view is loaded when no data source is set.
- **selection-and-depth-are-reconciled**: The component MUST NOT draw the
  card as the front card unless its highlighted state is `true`, regardless
  of the stack depth value most recently reported by the hosting bar,
  including the initial value of `0` before any bar has reported anything.
  When highlighted, the card draws at depth `0`; when not, the card draws at
  a depth of at least `1`, even if the reported depth is `0`.
- **front-card-overhangs-the-workspace-edge**: The card at depth `0` MUST
  have its painted background stand `1` point past the card's own bounds on
  the side facing the workspace.
- **behind-card-recedes-from-the-workspace-edge**: A card at a depth greater
  than `0` MUST have its painted background and its text pulled in from the
  card's bounds on every side, including the side facing the workspace, by
  an amount proportional to its depth.
- **vertical-edge-recession-accumulates-with-depth**: On a vertical edge
  (left or right), the recession at depth *n* (`1` ≤ *n* ≤ `3`) MUST equal
  `n × 4` points.
- **horizontal-edge-recession-is-constant**: On a horizontal edge (top or
  bottom), every card at a depth greater than `0` MUST recede by exactly `4`
  points, regardless of depth.
- **recession-does-not-increase-past-depth-three**: The component MUST NOT
  recede a card any further once its depth reaches `3`, even if a greater
  depth is reported.
- **paint-and-text-move-together**: A change of recession MUST move the
  card's painted background and its text column by the same amount.
- **depth-change-animates-when-attached-to-a-window**: When the card's view
  has a non-nil window, a change of stack depth MUST animate the move over
  `0.16` seconds with an ease-out timing curve.
- **depth-change-is-immediate-when-detached**: When the card's view has a
  nil window, a change of stack depth MUST apply the new position
  immediately, with no animation.
- **redundant-depth-set-is-a-no-op**: Setting the stack depth to its current
  value MUST NOT re-run the depth-change logic or start an animation.
- **card-width-is-bounded**: The card's measured width MUST be no less than
  `240` points and no more than `340` points, regardless of which edge
  hosts it.
- **card-height-has-a-floor-and-grows-with-content**: The card's measured
  height MUST be no less than `136` points and MUST grow to fit its content
  when the content needs more room.
- **front-and-behind-cards-differ-in-role-and-color**: The component MUST
  set each label's semantic text role according to whether the card is at
  depth `0` (front) or a depth greater than `0` (behind):

  | Label | Front role | Behind role |
  |-------|-----------|-------------|
  | Agent | `.accent` | `.primaryText` |
  | Session | `.primaryText` | `.secondaryText` |
  | Directory | `.secondaryText` | `.tertiaryText` |
  | Branch | `.secondaryText` | `.tertiaryText` |
  | Summary | `.secondaryText` | `.tertiaryText` |
- **front-and-behind-cards-use-distinct-backgrounds**: The component MUST
  paint the front card's background and border in the workspace's own
  backdrop and outline colors, and MUST paint a behind card's background and
  border in the bar's own window-background and border colors.
- **close-button-sits-on-the-outward-end**: On the left edge, the close
  button MUST appear as the first (leading) element of the card's header; on
  every other edge, it MUST appear as the last (trailing) element.
- **close-button-callback**: Clicking the close button MUST invoke the close
  callback, when one is set.
- **labels-do-not-intercept-clicks**: The agent, session, directory, branch,
  and summary labels MUST NOT be selectable, so that a click anywhere over
  them is left for the enclosing tab item's own click handling rather than
  starting a text selection.
- **status-glyph-has-an-accessible-label**: Each status glyph the component
  displays MUST carry the accessibility label supplied with it, independent
  of its symbol name.
- **subviews-carry-tab-scoped-accessibility-identifiers**: The card and each
  of its agent, session, directory, branch, summary, and close-button
  subviews MUST expose an accessibility identifier of the form
  `tab-pane.<part>.<tabID>`, scoped to the pane's own tab ID.
- **context-menu-is-delegated**: A right-click (or other menu-triggering
  event) on the card MUST show the menu the delegate supplies when it is
  non-nil, and MUST fall back to the platform's standard context menu when
  the delegate returns nil or is unset.
- **component-does-not-poll-its-data-source**: The component MUST NOT
  re-fetch or observe the data source on its own; content MUST change only
  in response to an explicit reload call.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

