
- **single-session-read**: Component MUST read its transcript only through
  the caller-supplied loader, which is already narrowed to one session, and
  MUST show only the rows that loader returns.
- **seeded-first-frame**: Component MUST show the caller-supplied seed rows
  from its first frame, before any read has completed, so it fades in
  holding the conversation rather than filling in afterwards.
- **seed-survives-early-send**: Component MUST keep the seed rows in the
  transcript when a line is sent before the first read lands, rather than
  publishing an empty transcript around the pending line.
- **periodic-refresh**: Component MUST re-read its conversation at the
  caller-supplied refresh interval for as long as it is presented.
- **on-demand-refresh**: Component MUST re-read its conversation
  immediately when its refresh operation is called, without waiting for the
  next interval.
- **stop-reading-before-fade**: Component MUST stop reading its conversation
  when dismissal begins, before the fade-out animation starts, and MUST also
  stop when the component is discarded.
- **fills-host**: Component MUST cover its whole host and MUST pin its
  transcript view to all four edges of itself, composer included.
- **transparent-transcript**: The transcript view MUST draw no background of
  its own, so the blurred feed shows through it.
- **terminal-bubble-style**: Component MUST draw its rows with the same
  terminal bubble shape the feed uses, not the chat window's speech bubble.
- **line-limit**: Component MUST show at most the caller-supplied number of
  lines of a message before offering the rest, and MUST show a message whole
  when the limit is absent.
- **composer-follows-sendability**: Component MUST enable its composer if and
  only if a send handler was supplied, and MUST show the composer greyed out,
  not removed, when none was.
- **composer-prompt**: Component MUST label its composer with the `>` prompt.
- **no-row-actions**: Component MUST NOT offer a row action of any kind: no
  open action, no jump-to-source action, and no row selection.
- **focus-composer-on-present**: Presenting the component MUST give the
  keyboard focus to the composer when a send handler was supplied, and MUST
  leave keyboard focus where it was when none was.
- **return-belongs-to-composer**: While the composer has the keyboard focus,
  the component MUST report Return and keypad Enter as unhandled by
  dismissal, so they reach the composer.
- **escape-always-dismisses**: Escape MUST dismiss the component whether or
  not the composer has the keyboard focus.
- **dismissal-gestures**: Component MUST dismiss itself on an unclaimed press
  and, when the composer does not have the focus, on Return, keypad Enter
  and Escape, and MUST NOT dismiss on any other key or on a press a bubble
  claimed.
- **stable-accessibility-id**: Component MUST expose the accessibility
  identifier `conversation-focus.overlay`.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

