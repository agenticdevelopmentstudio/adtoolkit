
- **tracks-active-node-per-window**: The component MUST maintain,
  independently for each window, at most one active pane node id at a time.
- **unclaimed-pane-counts-as-active**: Checking whether a view is in the
  active pane MUST return `true` for a view inside a pane backdrop whose
  window has no active node id recorded yet.
- **membership-decided-by-node-id-match**: Checking whether a view is in the
  active pane MUST return `true` for a view inside a pane backdrop only when
  that backdrop's node id equals the window's recorded active node id (or the
  window has none recorded, per **unclaimed-pane-counts-as-active**), and
  MUST return `false` otherwise.
- **view-outside-any-pane-counts-as-active**: Checking whether a view is in
  the active pane MUST return `true` for a view that has no pane backdrop
  anywhere among its ancestor views.
- **nil-window-has-no-active-node**: Looking up the active node id for a
  window MUST return none when passed no window.
- **is-in-active-pane-ignores-key-window**: Checking whether a view is in the
  active pane MUST return the same result regardless of whether its view's
  window is the focused window; which pane the user is working in does not
  change because a different window came forward.
- **a-hidden-pane-remains-live**: A pane counts as "live" — eligible to hold
  the active id, or to receive it as a departure's successor — as long as its
  backdrop remains anywhere in the window, even if hidden (for example, by a
  collapsed split). Only a pane removed from the window entirely stops
  counting as live.
- **arrival-claims-active-in-an-unclaimed-window**: A pane's arrival MUST
  activate the arriving pane when no live pane (per
  **a-hidden-pane-remains-live**) already on screen in that window holds the
  active id.
- **arrival-does-not-steal-active-from-a-live-pane**: A pane's arrival MUST
  NOT change the window's active id when a live pane (per
  **a-hidden-pane-remains-live**) already on screen in that window holds it.
- **arrival-enables-mouse-moved-tracking-when-setting-on**: A pane's arrival
  MUST enable pointer-move tracking on the window whenever the
  pointer-follows setting is enabled, regardless of whether the arriving pane
  becomes the active one.
- **departure-hands-off-to-a-surviving-pane**: A pane's departure MUST
  reassign the window's active id to another live pane (per
  **a-hidden-pane-remains-live**) in the same window when the departing pane
  held the active id and at least one other live pane remains.
- **departure-clears-active-id-when-no-pane-survives**: A pane's departure
  MUST remove the window's active-id entry entirely when the departing pane
  held the active id and no other live pane (per
  **a-hidden-pane-remains-live**) remains in that window.
- **departure-of-a-non-active-pane-is-inert**: A pane's departure MUST NOT
  alter the window's active id, and MUST NOT post a change notification, when
  the departing pane did not hold the active id.
- **window-close-clears-active-id-silently**: The component MUST remove a
  window's active-id entry when that window closes, and MUST NOT post a
  change notification when doing so.
- **close-and-highlight-changes-dispatch-through-the-main-queue**: The
  component MUST handle a window's close, and MUST have each pane backdrop
  handle a highlight-setting change, by dispatching onto the main work queue
  rather than a mechanism that pauses while an interaction is in progress, so
  the update still applies while the platform is in the middle of tracking a
  pointer gesture.
- **activation-is-idempotent**: Activating a node id MUST have no effect, and
  MUST NOT post a change notification, when the given node id already equals
  the window's current active id.
- **activation-posts-notification-on-change**: Activating a node id MUST post
  a change notification, with the window as its subject, whenever it changes
  the window's active id.
- **setting-enabled-reaches-already-open-windows**: Turning the
  pointer-follows setting on MUST enable pointer-move tracking on every
  window the component is already tracking, not only on windows opened after
  the change.
- **accepts-mouse-moved-is-never-reset-to-false**: The component MUST NOT
  disable pointer-move tracking on a window once enabled, even when the
  pointer-follows setting is or becomes disabled; disabling the setting only
  stops pointer-move events from being acted on, not received.
- **event-monitor-is-local-to-the-apps-own-windows**: The component MUST
  install its event monitor as a local monitor, not a global one, so it
  observes pointer events only inside this app's own windows and requires no
  special system permission.
- **clicks-are-evaluated-regardless-of-the-setting**: The event monitor MUST
  evaluate every primary-click and secondary-click event regardless of the
  pointer-follows setting.
- **mouse-moved-is-gated-by-the-setting**: A pointer-move event MUST be
  ignored unless the pointer-follows setting is enabled.
- **mouse-moved-is-gated-by-key-window**: A pointer-move event MUST be
  ignored when its window is not the focused window.
- **mouse-moved-is-gated-by-an-attached-sheet**: A pointer-move event MUST be
  ignored when its window has an attached sheet.
- **mouse-moved-is-gated-by-arrange-mode**: A pointer-move event MUST be
  ignored when arrange mode is enabled for that window.
- **an-event-with-no-window-is-ignored**: Recording an event MUST ignore
  (take no action for) any monitored event whose window is unset.
- **a-nil-content-view-means-no-pane**: Resolving a pane chain under a point
  MUST return none — no pane matched — for a window whose content view is
  unset, rather than treating any point in it as inside a pane.
- **event-outside-any-pane-is-ignored**: An event whose hit-tested point does
  not land inside any pane backdrop MUST be ignored.
- **event-on-the-already-active-pane-is-a-no-op**: An event, click or move,
  that hit-tests to the pane already holding the window's active id MUST
  cause no state change.
- **click-activates-a-different-pane-directly**: A primary or secondary click
  that hit-tests to a pane other than the currently active one MUST activate
  that pane.
- **mouse-moved-takes-focus-before-activating**: A pointer-move event that
  hit-tests to a pane other than the currently active one MUST attempt to
  move input focus into that pane before the pane is activated.
- **focus-refusal-blocks-mouse-moved-activation**: When the outgoing
  input-focus holder refuses to give up focus during the focus attempt a
  pointer-move event triggers, the hit-tested pane MUST NOT be activated.
- **the-event-monitor-never-consumes-an-event**: The local event monitor MUST
  return every event it observes unmodified.
- **focus-walk-proceeds-innermost-to-outermost**: Taking input focus within a
  hit-tested chain MUST offer input-focus status to the chain of views in
  innermost-to-outermost order, stopping at the first view that accepts it.
- **focus-walk-treats-the-current-responder-as-already-taken**: Taking input
  focus MUST treat a candidate view that already holds input focus as taken,
  without attempting to reassign focus to it again.
- **focus-walk-stops-on-outgoing-refusal**: Taking input focus MUST stop the
  walk and report a refusal the moment a focus-assignment attempt leaves the
  outgoing focus holder still in place.
- **focus-walk-restores-the-original-responder-on-exhaustion**: When no
  candidate in the chain accepts input-focus status, taking input focus MUST
  attempt to restore the original focus holder and, if that succeeds, MUST
  report that there was nowhere to put the keys.
- **focus-walk-reports-refused-when-restoration-fails**: When no candidate
  accepts input-focus status and the attempt to restore the original focus
  holder fails, taking input focus MUST report a refusal.
- **every-pane-is-always-outlined**: Applying the theme MUST draw a 2-point
  border on every pane backdrop, whether or not it is the active pane.
- **the-backdrop-is-always-the-pane-backdrop-color**: Applying the theme MUST
  set the view's background to the theme's pane-backdrop color regardless of
  active state.
- **the-active-pane-uses-the-accent-outline-color**: Applying the theme MUST
  color the border with the theme's active-pane-outline color when, and only
  when, the pane holds its window's active id, the window is focused, and the
  effective highlight setting is enabled. This check compares the active
  node id directly against the pane's own node id — it does not go through
  the "is in active pane" check. When the window has no recorded active id
  (see **unclaimed-pane-counts-as-active**), the comparison is against none,
  so no pane draws the accent, even though checking whether a view is in the
  active pane would report `true` for a view inside any of them.
- **every-other-pane-uses-the-hairline-outline-color**: Applying the theme
  MUST color the border with the theme's pane-outline color in every case
  that does not satisfy **the-active-pane-uses-the-accent-outline-color**.
- **the-accent-color-requires-a-focused-window**: Applying the theme MUST NOT
  use the accent border color when the pane's window is neither focused nor
  has a focused attached sheet, even when the pane holds that window's
  active id.
- **an-attached-sheet-counts-the-window-as-focused**: Applying the theme MUST
  treat the pane's window as focused when that window's attached sheet is the
  focused window, even when the window itself is not focused.
- **a-theme-override-takes-precedence-over-the-user-setting**: Applying the
  theme MUST use the current theme's project-level highlight override when
  the theme sets one, and MUST fall back to the user's highlight setting only
  when the theme does not.
- **the-fill-is-inset-from-the-backdrop-edges**: The pane's fill subview MUST
  be constrained on all four edges to the backdrop's own border inset (2
  points) inside the backdrop's own bounds.
- **the-fill-is-the-first-subview**: The fill subview MUST be added to the
  backdrop before any other subview, so chrome added later renders above it.
- **a-window-change-reports-departure-before-arrival**: Handling a change of
  window MUST report the backdrop's departure from its previous window, when
  it had one and it differs from the new one, before reporting its arrival in
  the new window.
- **the-backdrop-repaints-on-its-own-windows-activation-change**: The
  backdrop MUST reapply its theme when a tracker change notification is
  posted with its own window as the subject, and MUST ignore that
  notification for any other window.
- **the-backdrop-repaints-on-any-key-window-change**: The backdrop MUST
  reapply its theme whenever any window becomes or loses focus, not only its
  own.
- **the-backdrop-repaints-on-a-highlight-setting-change**: The backdrop MUST
  reapply its theme when the highlight setting changes.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

