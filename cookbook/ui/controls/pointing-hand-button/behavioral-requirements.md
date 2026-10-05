
- **cursor-rect**: The component MUST register the pointing-hand cursor
  over its full `bounds` via the platform's cursor-rect mechanism.
- **tracking-area-replacement**: WHEN the hover-tracking registration step
  runs, the component MUST first defer to the default tracking-area setup,
  and, if a previously registered hover-tracking region exists, MUST
  remove it before adding the new one.
- **always-active-tracking**: WHEN the hover-tracking registration step
  runs, the component MUST register a new hover-tracking region covering
  its full `bounds`, owned by itself, configured to report pointer entry,
  exit, and movement, and to remain active regardless of window focus, so
  tracking remains active whether or not the button's window has focus.
- **enter-cursor**: WHEN a pointer-entered event is delivered, the
  component MUST set the current cursor to the pointing-hand cursor.
- **move-cursor**: WHEN a pointer-moved event is delivered, the component
  MUST set the current cursor to the pointing-hand cursor.
- **exit-cursor**: WHEN a pointer-exited event is delivered, the component
  MUST set the current cursor to the default arrow cursor.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

