
Four small units answer one question for the rest of the application: is
this process one that must keep its hands off the desktop? The debug launch
switch is the reusable primitive — a settings-store key that doubles as a
launch-argument name, read only in a debug build. The quiet presentation
gate is the one switch built from it (keyed `"QuietWindowPresentation"`),
OR'd together with a second, independent signal — whether the process is a
test host, detected by checking whether the test framework's marker type is
resolvable in-process. A conditional activation operation and three
window-presentation operations (sink behind desktop, quiet order-front,
quiet make-key-and-order-front) are what the rest of the application calls
instead of unconditional application activation and unconditional window
ordering directly, so a test suite or an automated debug session can drive
real, on-screen, laid-out windows without ever pulling them — or the
application itself — in front of whoever is at the keyboard.

