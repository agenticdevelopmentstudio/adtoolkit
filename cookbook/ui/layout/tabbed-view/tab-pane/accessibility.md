
- **Role**: The pane view sets no explicit accessibility role of its own;
  it is inert content occupying a slot, not itself a control. Selection/tab
  semantics belong to the hosting bar (a sibling component, with its own
  recipe) via the stacked-item interfaces this controller conforms to.
- **Label requirements**: The agent, session, directory, branch, and summary
  labels expose their own text as their accessible content; each status
  glyph carries an explicit accessibility label from its own status-symbol
  value, independent of its symbol name. No single combined label
  summarizes the whole card - the screen reader visits each subview
  individually, in the header/session/directory/branch/summary layout
  order.
- **Announce state changes**: The component posts no accessibility
  notification of its own when the stack depth or highlighted state
  changes. Announcing that a tab became selected is the hosting bar's
  responsibility (it owns the selection semantics for the group), not this
  file's.
- **Minimum tap target**: The close button's hit area is fixed at `14 × 14`
  pt (both the button and its image carry explicit `14`-point width/height
  constraints, with no additional invisible padding) - well under the
  ~`44 × 44` pt comfortable-target guidance and under WCAG 2.5.8's `24 × 24`
  CSS px minimum. It is a standalone icon button, not inline text, so the
  inline-text exemption does not apply.
- **Identifiers**: The card and each of its agent, session, directory,
  branch, summary, and close-button subviews carry a stable
  `tab-pane.<part>.<tabID>` accessibility identifier, keyed to the pane's
  own tab ID.

