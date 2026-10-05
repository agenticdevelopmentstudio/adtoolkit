
- **Data collected**: Per window id and screen set, the window's frame
  (top-left offset, size, relative position), a save timestamp, and the
  screen's display identifier, localized name, resolution and main flag;
  per window id a visible/hidden flag.
- **Storage**: JSON blobs under keys of the form `WindowState_<id>` and
  booleans under keys of the form `WindowVisible_<id>`, each prefixed by the
  window-state namespace, in the platform's own local preferences store
  (default backend).
- **Transmission**: None; nothing leaves the device.
- **Retention**: A placement is kept until its screen set is unknown to the
  screen manager and older than the maximum set age, then dropped at the
  window's next save; the reset-frame, reset-all-frames, and
  clear-saved-state operations remove state on demand.

