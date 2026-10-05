
The engine lets a host app see and control the windows of *other*
applications. It is shared logic with no UI, made of six parts:

- **the window-control contract** — the operations (list, move, resize,
  focus, set frame) that orchestration code depends on so it can be tested
  with a mock.
- **the window manager** — the real implementation. It enumerates windows
  with the system's window list (no permission needed), applies an
  enumeration policy, backfills missing titles through the accessibility
  layer, and manipulates windows through accessibility elements.
- **the accessibility-element helper** — bridges a window's system-assigned
  identifier to an accessibility element by process ID plus a
  title/position/size score, and wraps the accessibility attribute reads,
  writes and the raise action.
- **the window observer** — watches app launch and termination and window
  created/destroyed/title-changed events (per-app accessibility observers)
  and reports them to a delegate.
- **control errors** — the typed errors of the control operations.
- **the accessibility permission helper** — the one place hosts check or
  prompt for accessibility trust; the engine itself never checks it.

Windows are described by a window record: `id` (the window's
system-assigned identifier), `app`, `pid`, `title`, `frame` (global
top-left-origin coordinates), `display`, `isOnScreen`, `layer`, plus an
operation that returns a copy with only the title replaced. Use the
engine for window-context switching, window explorers and any feature that
parks, restores or raises third-party windows.

