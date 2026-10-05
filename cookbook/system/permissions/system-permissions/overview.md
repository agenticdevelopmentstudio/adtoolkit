
This is the platform-free (UI-framework-free, daemon-linkable) permissions
layer of the toolkit, covering the operating system's per-permission privacy grants. It
consists of:

- a permission model — a set of the operating-system privacy grants a host app may
  need (accessibility, notifications, automation targeting a bundle
  identifier, location, microphone, screen capture, keychain access to a
  named service) with per-case metadata: a display name, a stable
  identifier token, an icon name, an explanation, a settings-pane
  location, and an action title.
- a status value — the tri-state result granted / denied / undetermined.
- a status-checking contract — an operation that reads status without
  prompting, and an operation that surfaces the system's own request
  flow, plus a granted-check convenience.
- a production status checker — the real conformance over the underlying
  platform APIs, with the Apple Events probe injected as a separate
  dependency.
- a keychain grant ledger — a persisted record of what the app last
  learned about reading a given keychain item, because the platform offers no
  way to simply ask.

Use it wherever an app or daemon has to show or obtain a privacy grant;
the UI that renders it lives in
[Permission Row View](adtoolkit://cookbook/system/permissions/permission-row-view)
and
[Permissions Panel View](adtoolkit://cookbook/system/permissions/permissions-panel-view).

