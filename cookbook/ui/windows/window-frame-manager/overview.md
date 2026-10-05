
The window frame manager is the toolkit's window-frame persistence service.
It:

- holds a registry of window specs keyed by window id (default size, minimum
  size, default position, and whether frame and visibility persist);
- restores a window's frame on first show from the placement saved for the
  current screen set, or applies the spec's default position;
- saves a window's frame on every move or resize as a placement keyed by the
  current screen-set id, so a laptop that docks at several desks remembers
  one position per desk;
- repositions managed windows when the screen manager reports a screen
  change;
- persists a window's visible/hidden flag independently of its frame.

Positions are anchored at the window's **top-left** corner from the user's
point of view (x grows right, y grows **down** from the top of the screen's
visible area). Restoring in the same screen set on an exactly matching screen
replays the saved absolute offset, so content-driven resizes cannot walk the
window between launches; a relative (travel-fraction) position is used only
when the literal geometry no longer applies.

The frame math is a pure, side-effect-free library also used directly by
content-hugging windows (the content-hugging frame calculation).

The manager is owned by the window manager. Usage per its own documentation:
register specs at startup, restore a window's frame after creating it, and
save a window's frame on move/resize (the single-instance window base does
this from its own move/resize/close callbacks).

