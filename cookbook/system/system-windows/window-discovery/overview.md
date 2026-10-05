
The window discovery view model (with its two value types, a discovered window and a discovered app) backs the Window Discovery panel. Given a session, it:

- enumerates every window the window-management engine reports — including
  minimized and off-screen windows — and keeps the titled ones owned by regular,
  user-visible applications;
- groups them by owning process into discovered-app values carrying the app's
  localized name and icon;
- flags each window whose title matches the session's project name, using the
  per-app title heuristic from the shared heuristic registry with a raw-title
  fallback (a static matching function);
- sorts apps with a match first, then alphabetically;
- focuses a chosen window through the engine and tells its host when the focus
  succeeded so the panel can close.

It needs only Accessibility permission. When the system window list omits a
title (it does for other apps without Screen Recording permission), the engine
backfills it from the Accessibility API before this model sees it.

Use it when a UI needs a "which window belongs to this session?" chooser. It
is observable; the host binds to its three published properties.

