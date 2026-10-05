
- **Role/trait**: A tab button exposes itself as a single accessibility
  element with a button role, which stops its subviews from being
  separately exposed (**tab-button-is-accessible-element**). The
  hosted-item wrapper and the bar itself set no accessibility role of their
  own — they are plain layout/click-forwarding containers, not controls; a
  content-hosting item's own accessible content is entirely the hosted
  content's concern.
- **Label requirements**: A title tab exposes its title text via its
  accessibility title (**tab-button-title-updates-accessibility**); its
  close button carries its own identifier (`tab-bar.close.<uuid>`, distinct
  per tab since several bars can be on screen at once) and the description
  "Close Tab", and is the sole entry the tab button republishes as its
  accessibility children once it becomes its own element
  (**close-button-republished-as-sole-child**).
- **Announce state changes**: A tab button's highlighted-state change
  updates that button's own accessibility value on every change, whether it
  originates from a click or from a caller setting the selection
  (**tab-button-highlight-updates-accessibility-value**) — so, unlike a
  purely click-driven implementation, this concept's own value updates are
  consistent for both origins. No accessibility notification is posted
  anywhere in this concept when the active tab changes; a screen-reader
  user whose cursor is positioned elsewhere is not told that a different
  tab became selected — the update relies entirely on the moved focus
  element's own accessibility value being read if and when the cursor lands
  there.
- **Keyboard / assistive-technology navigation**: The tab button and
  hosted-item wrapper are plain view types with no keyboard-focus
  acceptance, key-handling, or key-view-loop wiring; a tab is reachable
  only by a pointer click or an existing assistive-technology cursor's
  activation gesture. The close button is a real button control and so
  remains independently reachable through the platform's own
  keyboard-navigation loop, meaning a keyboard-only user may be able to
  close a tab yet has no way at all to select one — there is no
  keyboard-only path to move focus onto a tab and activate it without a
  pointer or assistive cursor already positioned there.
- **Minimum tap target**: The close button's hit area is a fixed
  `14×14pt`; the rest of the tab button (background, label) is clickable
  everywhere outside that frame. This is a pointer-driven desktop concept;
  the `44×44pt` (phone) / `48×48dp` (Android) touch-target minimums do not
  apply directly here and instead inform the touch-platform translations in
  Platform Notes.

