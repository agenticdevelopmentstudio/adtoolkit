
- The picker contributes one accessible name: the title (default
  "Choose an address") is passed straight through as the composed
  command palette's accessible label, which names both the modal's
  hidden heading and the search field/listbox for assistive technology.
- All other accessibility mechanics are inherited by composition, not
  implemented by the picker itself: the search field behaves as a
  combo-box-style input associated with the results list, and tracks
  which row is highlighted; results sit in a listbox-like structure with
  grouped, selectable rows; arrow keys, Home/End, and Enter move and
  commit the highlight; Escape closes via the underlying modal's own
  handling. These are the composed command-search interaction's
  contract, not the picker's own logic, and that composed interaction
  has no ingredient of its own yet in this cookbook — this section
  describes what the picker actually gets by composing it.
- Each result's entity-type badge is rendered as visible text (not a
  color-only cue), so entity type reads without color.
- Touch/click target sizing for the search field, result rows, and
  dialog chrome is the composed interaction's rendering, not a value the
  picker chooses; the picker supplies no sizing of its own to evaluate
  here.

