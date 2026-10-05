
- **Role/trait**: A tab button exposes itself as a button-role accessibility
  element and suppresses its subviews from being separately exposed, so it
  reads as one control rather than several. The view's own container and the
  shared content area expose no accessibility role — not applicable, they
  are plain layout containers, not controls.
- **Label requirements**: A title-only tab exposes its title text as its
  accessibility title; its close button carries its own identifier
  (`tab-bar.close.<uuid>`, distinct per tab since several bars can be on
  screen at once) and description ("Close Tab"), and is the sole element
  republished as that tab's accessible child once the tab becomes its own
  accessibility element. A content-hosting tab's own accessible content is
  entirely the hosted content's concern — this component only forwards a
  highlighted state and a close notification when the hosted content opts
  in.
- **Announce state changes**: A tab button's highlighted-state change
  updates that button's own accessibility value, so a click-driven selection
  is reflected on the pressed element itself, but no accessibility
  notification is posted anywhere in this concept when the active tab
  changes programmatically — a fallback activation after removing a tab,
  toggling an edge, or the sibling-selection update across an edge's other
  tabs. A screen-reader user tracking a different element is not told the
  active tab changed when no click of their own caused it.
- **Keyboard / assistive-technology navigation**: The tab button and
  hosted-item wrapper are plain view types with no keyboard-focus
  acceptance, key-handling, or key-view-loop wiring; a tab is reachable only
  by a pointer click or an existing assistive-technology cursor's activation
  gesture. There is no way for a keyboard-only or switch-access user to move
  focus onto a tab and activate it without a pointer or assistive cursor
  already positioned there.
- **Minimum tap target**: The close button's hit area is a fixed `14×14pt`;
  the tab body (background, label, close button) is larger than that and is
  clickable everywhere outside the close button's own frame. This is a
  pointer-driven desktop concept; the `44×44pt` (phone) / `48×48dp`
  (Android) touch-target minimums do not apply directly here and instead
  inform the touch-platform translations in Platform Notes.

